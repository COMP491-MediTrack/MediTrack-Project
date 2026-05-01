import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:injectable/injectable.dart';
import '../models/pharmacy_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class PharmacyRemoteDataSource {
  Future<List<PharmacyModel>> getOnDutyPharmacies(String city, {String? district});
}

@LazySingleton(as: PharmacyRemoteDataSource)
class PharmacyRemoteDataSourceImpl implements PharmacyRemoteDataSource {
  // Separate Dio instance — no base URL, used for direct eczaneler.gen.tr scraping
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'tr-TR,tr;q=0.9',
      'Referer': 'https://www.eczaneler.gen.tr/',
    },
  ));

  static const _cityMap = {
    'afyon': 'afyonkarahisar',
    'icel': 'mersin',
    'k.maras': 'kahramanmaras',
  };

  static String _slugify(String text) {
    text = text.toLowerCase();
    for (final suffix in [' ili', ' province', ' belediyesi', ' valiliği']) {
      text = text.replaceAll(suffix, '');
    }
    text = text.trim();
    const tr = {'ı': 'i', 'ş': 's', 'ç': 'c', 'ğ': 'g', 'ü': 'u', 'ö': 'o', 'İ': 'i'};
    for (final e in tr.entries) {
      text = text.replaceAll(e.key, e.value);
    }
    return text.replaceAll(RegExp(r'[^a-z0-9-]'), '');
  }

  @override
  Future<List<PharmacyModel>> getOnDutyPharmacies(String city, {String? district}) async {
    try {
      final citySlug = _cityMap[_slugify(city)] ?? _slugify(city);

      assert(() {
        developer.log('Fetching on-duty pharmacies for city: $city, district: $district');
        return true;
      }());

      // Try district page first — much faster, avoids scanning all districts
      if (district != null && district.isNotEmpty) {
        final districtSlug = _slugify(district);
        final url = 'https://www.eczaneler.gen.tr/nobetci-$citySlug-$districtSlug';
        assert(() {
          developer.log('Trying district URL: $url');
          return true;
        }());
        try {
          final res = await _dio.get<String>(url, options: Options(responseType: ResponseType.plain));
          if (res.statusCode == 200 && res.data != null) {
            final pharmacies = _parsePharmacies(res.data!);
            if (pharmacies.isNotEmpty) {
              assert(() {
                developer.log('District page returned ${pharmacies.length} pharmacies');
                return true;
              }());
              return pharmacies;
            }
          }
        } catch (_) {}
      }

      // Fallback: city page (smaller cities list pharmacies directly)
      final cityUrl = 'https://www.eczaneler.gen.tr/nobetci-$citySlug';
      assert(() {
        developer.log('Falling back to city URL: $cityUrl');
        return true;
      }());
      final res = await _dio.get<String>(cityUrl, options: Options(responseType: ResponseType.plain));
      if (res.statusCode != 200 || res.data == null) {
        throw ServerException('Could not fetch pharmacies (status ${res.statusCode})');
      }

      final pharmacies = _parsePharmacies(res.data!);
      assert(() {
        developer.log('City page returned ${pharmacies.length} pharmacies');
        return true;
      }());
      if (pharmacies.isNotEmpty) return pharmacies;

      throw ServerException('No pharmacies found for $city');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  List<PharmacyModel> _parsePharmacies(String htmlBody) {
    final document = html_parser.parse(htmlBody);
    final rows = document.querySelectorAll('tr');
    final pharmacies = <PharmacyModel>[];

    for (final row in rows) {
      final nameEl = row.querySelector('span.isim');
      if (nameEl == null) continue;

      final name = nameEl.text.trim();
      final addressEl = row.querySelector('div.col-lg-6');
      final phoneEl = row.querySelector('div.col-lg-3.py-lg-2');
      final badgeEl = row.querySelector('span.bg-secondary') ?? row.querySelector('span.bg-info');

      final address = addressEl?.text.trim() ?? '';
      final phone = phoneEl?.text.trim() ?? '';
      final district = badgeEl?.text.trim() ?? '';

      if (name.length > 2) {
        pharmacies.add(PharmacyModel(
          name: name,
          address: address,
          phone: phone,
          district: district,
          latitude: 0.0,
          longitude: 0.0,
        ));
      }
    }

    return pharmacies;
  }
}
