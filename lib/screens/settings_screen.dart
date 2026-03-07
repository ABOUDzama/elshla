import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = SettingsService.isSoundEnabled;
  bool _vibrationEnabled = SettingsService.isVibrationEnabled;

  String _lastSyncInfo = 'جاري التحقق...';
  bool _isLoadingSync = true;

  @override
  void initState() {
    super.initState();
    _loadSyncInfo();
  }

  Future<void> _loadSyncInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_sync_date');
      if (lastSyncStr != null && lastSyncStr.isNotEmpty) {
        final lastSyncDate = DateTime.parse(lastSyncStr);
        final diff = DateTime.now().difference(lastSyncDate);
        if (diff.inDays == 0) {
          _lastSyncInfo = 'تم التحديث اليوم';
        } else if (diff.inDays == 1) {
          _lastSyncInfo = 'تم التحديث أمس';
        } else {
          _lastSyncInfo = 'تم التحديث منذ ${diff.inDays} أيام';
        }
      } else {
        _lastSyncInfo = 'يعمل بالأسئلة الأساسية';
      }
    } catch (e) {
      _lastSyncInfo = 'الأسئلة الأساسية النشطة';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSync = false;
        });
      }
    }
  }

  Future<void> _performManualSync() async {
    if (SettingsService.isAiEnabled) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('خيارات المزامنة'),
          content: const Text(
            'هل تريد المزامنة من السحابة أم توليد أسئلة جديدة بالذكاء الاصطناعي؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cloud'),
              child: const Text('السحابة'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'ai'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('الذكاء الاصطناعي ✨'),
            ),
          ],
        ),
      );

      if (choice == 'ai') {
        return _performAiSync();
      } else if (choice == null) {
        return;
      }
    }

    _syncFromCloud();
  }

  Future<void> _syncFromCloud() async {
    setState(() => _isLoadingSync = true);
    try {
      // Logic for cloud sync (simulated for this example as there's no real backend yet)
      await Future.delayed(const Duration(seconds: 2));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_date', DateTime.now().toIso8601String());
      await _loadSyncInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت المزامنة من السحابة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل المزامنة: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSync = false);
      }
    }
  }

  Future<void> _performAiSync() async {
    setState(() => _isLoadingSync = true);
    try {
      // In a real scenario, we'd loop through categories and update OnlineDataService cache
      // Here we simulate refreshing a few major categories via AI
      await Future.delayed(const Duration(seconds: 3));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_date', DateTime.now().toIso8601String());
      await _loadSyncInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت المزامنة وتوليد المحتوى بالـ AI بنجاح ✨'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل مزامنة الـ AI: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSync = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingTile(
            title: 'المؤثرات الصوتية',
            subtitle: 'تشغيل أو إيقاف أصوات الألعاب',
            icon: Icons.volume_up,
            value: _soundEnabled,
            onChanged: (value) async {
              await SettingsService.setSoundEnabled(value);
              setState(() => _soundEnabled = value);
            },
          ),
          const Divider(),
          _buildSettingTile(
            title: 'الاهتزاز',
            subtitle: 'تشغيل أو إيقاف الاهتزاز عند اللمس أو الخسارة',
            icon: Icons.vibration,
            value: _vibrationEnabled,
            onChanged: (value) async {
              await SettingsService.setVibrationEnabled(value);
              setState(() => _vibrationEnabled = value);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text(
              'مزامنة الأسئلة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_lastSyncInfo),
            leading: _isLoadingSync
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.deepOrange,
                    ),
                  )
                : const Icon(Icons.cloud_sync, color: Colors.deepOrange),
            trailing: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: _isLoadingSync ? null : _performManualSync,
              tooltip: 'تحديث الآن',
            ),
          ),
          const Divider(),
          _buildAiSettingsSection(),
          const Divider(),
          ListTile(
            title: const Text(
              'عن التطبيق',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('ألعاب الأصدقاء - النسخة الماركة'),
            leading: const Icon(Icons.info_outline, color: Colors.deepOrange),
            trailing: const Text('v0.2.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'إعدادات الذكاء الاصطناعي (GitHub AI)',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ),
        ListTile(
          title: const Text('GitHub Personal Access Token'),
          subtitle: Text(
            SettingsService.githubToken.isEmpty
                ? 'لم يتم تعيين مفتاح بعد'
                : 'تم ضبط المفتاح بنجاح',
          ),
          leading: const Icon(Icons.key, color: Colors.amber),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showTokenInputDialog,
          ),
        ),
        SwitchListTile(
          title: const Text('تفعيل توليد الأسئلة بالـ AI'),
          subtitle: const Text(
            'سيتم استخدام الذكاء الاصطناعي لتوليد أسئلة غير منتهية',
          ),
          value: SettingsService.isAiEnabled,
          onChanged: SettingsService.githubToken.isEmpty
              ? null
              : (value) {
                  // Re-render to show potential status changes if needed
                  setState(() {});
                },
          activeThumbColor: Colors.deepOrange,
          secondary: const Icon(Icons.auto_awesome, color: Colors.purple),
        ),
      ],
    );
  }

  void _showTokenInputDialog() {
    final controller = TextEditingController(text: SettingsService.githubToken);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال GitHub Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'استخدم GitHub Personal Access Token (PAT) لتفعيل الذكاء الاصطناعي.',
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'ghp_...'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SettingsService.setGithubToken(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
              }
              setState(() {});
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      secondary: Icon(icon, color: Colors.deepOrange),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.deepOrange,
    );
  }
}
