import '../../domain/broiler/broiler_grower_library.dart';

/// Real broiler-house photos that follow the flock's age, so the picture on
/// screen looks like the birds in the farmer's own house.
///
/// Phases come from `BroilerGrowerLibrary` (Ross-308): starter days 1–10,
/// grower 11–24, finisher 25–42. Sources and licences: `assets/images/CREDITS.md`
/// and [PhotoCredit.all] (shown in Settings → About).
abstract final class BroilerPhotos {
  static const starter = 'assets/images/broiler_starter.jpg';
  static const grower = 'assets/images/broiler_grower.jpg';
  static const finisher = 'assets/images/broiler_finisher.jpg';

  /// Fixed photos for cards that don't depend on the flock's age.
  static const chicksCloseup = 'assets/images/chicks_closeup.jpg';
  static const chicksFeederLine = 'assets/images/chicks_feeder_line.jpg';
  static const farmAerial = 'assets/images/broiler_farm_aerial.jpg';
  static const feed = 'assets/images/broiler_feed.jpg';

  /// The photo for batch [day] (clamped to 1–42 by the library).
  static String forDay(int day) {
    switch (BroilerGrowerLibrary.specForDay(day).phaseKey) {
      case 'pre_starter':
      case 'starter':
        return starter;
      case 'grower':
        return grower;
      default:
        return finisher;
    }
  }
}

/// Where a bundled photo came from. CC BY-SA photos must be credited;
/// public-domain and CC0 ones are listed as a courtesy.
class PhotoCredit {
  final String asset;
  final String title;
  final String author;
  final String licence;
  final String? licenceUrl;
  final String url;

  const PhotoCredit({
    required this.asset,
    required this.title,
    required this.author,
    required this.licence,
    this.licenceUrl,
    required this.url,
  });

  static const all = [
    PhotoCredit(
      asset: BroilerPhotos.starter,
      title: 'Baby chickens in a grower broiler house. (24993924222)',
      author: 'USDA NRCS Texas',
      licence: 'Public domain',
      url:
          'https://commons.wikimedia.org/wiki/File:Baby_chickens_in_a_grower_broiler_house._(24993924222).jpg',
    ),
    PhotoCredit(
      asset: BroilerPhotos.grower,
      title: 'Broiler Chickens 002',
      author: 'Icem4k',
      licence: 'CC BY-SA 4.0',
      licenceUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
      url: 'https://commons.wikimedia.org/wiki/File:Broiler_Chickens_002.jpg',
    ),
    PhotoCredit(
      asset: BroilerPhotos.finisher,
      title: '20130822-OC-RBN-2946 (9682285758)',
      author: 'USDA (Bob Nichols)',
      licence: 'Public domain',
      url:
          'https://commons.wikimedia.org/wiki/File:20130822-OC-RBN-2946_(9682285758).jpg',
    ),
    PhotoCredit(
      asset: BroilerPhotos.chicksCloseup,
      title: 'Broiler chicks Armenia 01',
      author: 'Narek Avetisyan',
      licence: 'CC BY-SA 4.0',
      licenceUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
      url:
          'https://commons.wikimedia.org/wiki/File:Broiler_chicks_Armenia_01.jpg',
    ),
    PhotoCredit(
      asset: BroilerPhotos.chicksFeederLine,
      title: 'Baby chickens in a grower broiler house. (25112103855)',
      author: 'USDA NRCS Texas',
      licence: 'Public domain',
      url:
          'https://commons.wikimedia.org/wiki/File:Baby_chickens_in_a_grower_broiler_house._(25112103855).jpg',
    ),
    PhotoCredit(
      asset: BroilerPhotos.farmAerial,
      title: 'Poultry farm 01',
      author: 'Wikideas1',
      licence: 'CC0',
      url: 'https://commons.wikimedia.org/wiki/File:Poultry_farm_01.jpg',
    ),
    PhotoCredit(
      asset: BroilerPhotos.feed,
      title: 'Poultry Feed Study - 49557307217',
      author: 'Fred Miller, Arkansas Agricultural Experiment Station',
      licence: 'CC BY-SA 2.0',
      licenceUrl: 'https://creativecommons.org/licenses/by-sa/2.0/',
      url:
          'https://commons.wikimedia.org/wiki/File:Poultry_Feed_Study_-_49557307217.jpg',
    ),
  ];
}
