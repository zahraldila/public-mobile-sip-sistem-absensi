import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'core/config/supabase_config.dart';
import 'screens/success_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Stream<DateTime> _timeStream;
  
  String? _logoUrl;
  String _companyName = 'PT Selada Indonesia Produktif';
  bool _isLoadingProfile = true;
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
    _fetchCompanyProfile();
    _initNfc();
  }

  Future<void> _initNfc() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (isAvailable) {
        NfcManager.instance.startSession(
          pollingOptions: {
            NfcPollingOption.iso14443,
            NfcPollingOption.iso15693,
            NfcPollingOption.iso18092,
          },
          onDiscovered: (NfcTag tag) async {
            String nfcId = '';
            
            try {
              // Di nfc_manager versi terbaru, tag.data bisa berupa object TagPigeon
              final dynamic pigeonTag = tag.data;
              if (pigeonTag != null) {
                // Mengambil property 'id' (Uint8List) dari TagPigeon
                final List<int> idList = pigeonTag.id;
                nfcId = idList.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
              }
            } catch (e) {
              debugPrint('Gagal membaca ID NFC: $e');
            }

            if (nfcId.isNotEmpty) {
              _handleNFCTap(nfcId);
            }
          },
        );
      }
    } catch (e) {
      debugPrint('Error init NFC: $e');
    }
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _fetchCompanyProfile() async {
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('settings')
          .select('key, value');
          
      if (data.isNotEmpty && mounted) {
        String? logoPath;
        String? name;
        
        for (var row in data) {
          if (row['key'] == 'company_name') {
            name = row['value']?.toString();
          } else if (row['key'] == 'company_logo') {
            logoPath = row['value']?.toString();
          }
        }
        
        setState(() {
          if (logoPath != null && logoPath.isNotEmpty) {
            _logoUrl = '${SupabaseConfig.url}/storage/v1/object/public/$logoPath';
          }
          if (name != null && name.isNotEmpty) {
            _companyName = name;
          }
          _isLoadingProfile = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Widget _buildDefaultLogo() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'SIP',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Future<void> _handleNFCTap(String nfcId) async {
    if (_isCheckingIn) return;
    setState(() => _isCheckingIn = true);

    try {
      // 1. Cari data kartu di tabel 'nfc'
      // TODO: Ganti 'uid' dengan nama kolom ID kartu NFC, dan 'nip' dengan nama kolom relasinya
      final nfcData = await Supabase.instance.client
          .from('nfc')
          .select('pegawai_id')
          .eq('nfc_serial_number', nfcId)
          .maybeSingle();

      if (nfcData == null || nfcData['pegawai_id'] == null) {
        throw Exception('Kartu NFC tidak terdaftar');
      }

      // 2. Cari profil pegawai berdasarkan NIP dari kartu
      final data = await Supabase.instance.client
          .from('pegawai')
          .select('nama_pegawai, nip, status, foto_profile')
          .eq('id', nfcData['pegawai_id'])
          .maybeSingle();

      if (mounted) {
        setState(() => _isCheckingIn = false);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(
              employeeName: data != null ? (data['nama_pegawai']?.toString() ?? 'Unknown') : 'Data Kosong',
              employeeId: data != null ? (data['nip']?.toString() ?? 'N/A') : 'N/A',
              checkInTime: _formatTime(DateTime.now()),
              checkInDate: _formatDate(DateTime.now()),
              status: data != null ? (data['status']?.toString() ?? 'WFO') : 'WFO',
              profileImageUrl: data != null && data['foto_profile'] != null 
                  ? '${SupabaseConfig.url}/storage/v1/object/public/${data['foto_profile']}'
                  : null,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error simulasi NFC: $e');
      if (mounted) {
        setState(() => _isCheckingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data akun: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime time) {
    const days = {
      1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis', 5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'
    };
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final dayName = days[time.weekday]!;
    final monthName = months[time.month - 1];
    
    return '$dayName, ${time.day} $monthName ${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Light background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              // Top Bar
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: _isLoadingProfile 
                      ? const Center(
                          child: SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        )
                      : (_logoUrl != null && _logoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                _logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildDefaultLogo(),
                              ),
                            )
                          : _buildDefaultLogo()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isLoadingProfile
                      ? Container(
                          height: 20,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Text(
                          _companyName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // Time & Date
              StreamBuilder<DateTime>(
                stream: _timeStream,
                initialData: DateTime.now(),
                builder: (context, snapshot) {
                  final time = snapshot.data!;
                  return Column(
                    children: [
                      Text(
                        _formatTime(time),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(time),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8E8E8E),
                        ),
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 48),
              // NFC Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Masih bisa disentuh untuk simulasi (misal di emulator yang tidak ada NFC)
                    _handleNFCTap('SIMULASI_ID');
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // NFC Circle
                      Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD6E2FC),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2B5BE3),
                            shape: BoxShape.circle,
                          ),
                          child: _isCheckingIn 
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : const Icon(
                                Icons.contactless,
                                color: Colors.white,
                                size: 54,
                              ),
                        ),
                      ),
                      const SizedBox(height: 56),
                      // Text
                      const Text(
                        'TEMPELKAN KARTU NFC',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA3D8BD),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFF138A5F),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'READY TO SCAN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF116B48),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
