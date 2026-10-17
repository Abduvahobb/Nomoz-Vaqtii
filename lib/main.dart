import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NamozApp());

class City {
  final String name;
  final double lat;
  final double lng;
  const City(this.name, this.lat, this.lng);
}

const cities = [
  City('Toshkent', 41.2995, 69.2401),
  City('Samarqand', 39.6542, 66.9597),
  City('Buxoro', 39.7747, 64.4286),
  City('Andijon', 40.7821, 72.3442),
  City('Namangan', 40.9983, 71.6726),
  City("Farg'ona", 40.3842, 71.7843),
  City('Qarshi', 38.8606, 65.7891),
  City('Nukus', 42.4531, 59.6103),
  City('Urganch', 41.5506, 60.6317),
  City('Termiz', 37.2242, 67.2783),
  City('Jizzax', 40.1158, 67.8422),
  City('Guliston', 40.4897, 68.7842),
  City('Navoiy', 40.0844, 65.3792),
];

const prayerNames = {
  'Fajr': 'Bomdod',
  'Sunrise': 'Quyosh',
  'Dhuhr': 'Peshin',
  'Asr': 'Asr',
  'Maghrib': 'Shom',
  'Isha': 'Xufton',
};

const months = [
  'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
  'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
];

class NamozApp extends StatelessWidget {
  const NamozApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namoz vaqtlari',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  City city = cities.first;
  Map<String, String>? times;
  String? error;
  bool loading = true;
  DateTime now = DateTime.now();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _init();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = DateTime.now();
      if (n.day != now.day && !loading) {
        now = n;
        _load();
      } else {
        setState(() => now = n);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('city');
    city = cities.firstWhere((c) => c.name == saved, orElse: () => cities.first);
    await _load();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final d = DateTime.now();
    final key = 'times_${city.name}_${d.year}-${d.month}-${d.day}';

    final cached = prefs.getString(key);
    if (cached != null) {
      setState(() {
        times = Map<String, String>.from(jsonDecode(cached));
        loading = false;
      });
      return;
    }

    try {
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/${_two(d.day)}-${_two(d.month)}-${d.year}'
        '?latitude=${city.lat}&longitude=${city.lng}'
        '&method=3&school=1&timezonestring=Asia/Tashkent',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = jsonDecode(res.body)['data']['timings'] as Map<String, dynamic>;
      final map = {
        for (final k in prayerNames.keys) k: (data[k] as String).substring(0, 5),
      };
      await prefs.setString(key, jsonEncode(map));
      if (!mounted) return;
      setState(() {
        times = map;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Internetga ulanib bo'lmadi. Qayta urinib ko'ring.";
        loading = false;
      });
    }
  }
