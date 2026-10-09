import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/constants.dart';

class RegionScreen extends StatefulWidget {
  const RegionScreen({super.key});

  @override
  State<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends State<RegionScreen> {
  String _selectedDistrict = AppConstants.districts.first;
  String _searchQuery = '';
  String _lang = 'uz';

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
    });
  }

  Future<void> _proceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmer_district', _selectedDistrict);
    if (!mounted) return;
    context.go('/onboarding/batch');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = _lang == 'ru';
    final isEn = _lang == 'en';

    final filtered = AppConstants.districts.where((d) {
      return d.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Выбор региона' : (isEn ? 'Select Region' : 'Viloyatni tanlang')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isRu
                    ? 'Где расположена ваша ферма?'
                    : (isEn ? 'Where is your poultry farm located?' : 'Parrandaxonangiz qaysi hududda joylashgan?'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isRu
                    ? 'Это необходимо для связи с местными ветеринарами'
                    : (isEn ? 'Required for regional veterinarian connection & localized weather' : "Bu mahalliy veterinar shifokorlar bilan bog'lanish uchun zarur"),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: isRu ? 'Поиск региона...' : (isEn ? 'Search region...' : 'Qidirish...'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final district = filtered[index];
                    final isSelected = district == _selectedDistrict;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      selected: isSelected,
                      selectedTileColor: theme.colorScheme.primary.withAlpha(20),
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: isSelected ? theme.colorScheme.primary : Colors.grey,
                      ),
                      title: Text(
                        district,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => setState(() => _selectedDistrict = district),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isRu ? 'Далее' : (isEn ? 'Next' : 'Keyingisi'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
