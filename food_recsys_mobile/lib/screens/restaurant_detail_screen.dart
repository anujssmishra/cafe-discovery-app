import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final ApiService apiService;
  final String restaurantId;
  final Restaurant? initialRestaurant;

  const RestaurantDetailScreen({
    super.key,
    required this.apiService,
    required this.restaurantId,
    this.initialRestaurant,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late Future<Restaurant> _restaurant;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.apiService.getRestaurant(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant details')),
      body: FutureBuilder<Restaurant>(
        future: _restaurant,
        builder: (context, snapshot) {
          final restaurant = snapshot.data ?? widget.initialRestaurant;
          if (restaurant == null) {
            if (!snapshot.hasError)
              return const Center(child: CircularProgressIndicator());
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Restaurant details could not be loaded.'),
              TextButton(
                onPressed: () => setState(() => _restaurant =
                    widget.apiService.getRestaurant(widget.restaurantId)),
                child: const Text('Retry details'),
              ),
            ]));
          }
          return _buildDetails(restaurant, snapshot.hasError);
        },
      ),
    );
  }

  Widget _buildDetails(Restaurant restaurant, bool refreshFailed) {
    final coordinatesKnown =
        restaurant.latitude != null && restaurant.longitude != null;
    final query = coordinatesKnown
        ? '${restaurant.latitude},${restaurant.longitude}'
        : [
            restaurant.name,
            restaurant.address ?? '',
            restaurant.area,
            restaurant.city
          ].where((part) => part.isNotEmpty).join(', ');
    final directions = Uri.https(
        'www.google.com', '/maps/search/', {'api': '1', 'query': query});
    final website = Uri.tryParse(restaurant.website ?? '');
    final image = restaurant.heroImageUrl ?? restaurant.photoUrl;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (refreshFailed)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
                'Could not refresh details. Showing the restaurant information already loaded.',
                style: TextStyle(color: AppTheme.warning)),
          ),
        if (image != null && image.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(image,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        const SizedBox(height: 16),
        Text(restaurant.name.isEmpty ? 'Name unavailable' : restaurant.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text([restaurant.area, restaurant.city]
            .where((part) => part.isNotEmpty)
            .join(', ')),
        const SizedBox(height: 8),
        Text(restaurant.address?.isNotEmpty == true
            ? restaurant.address!
            : 'Address not recorded'),
        Text(restaurant.priceBand == 'unknown'
            ? 'Price tier unknown'
            : 'Price tier: ${restaurant.priceBand}'),
        Text(restaurant.avgRating == null
            ? 'Rating not recorded'
            : 'Recorded rating: ${restaurant.avgRating!.toStringAsFixed(1)}'),
        const SizedBox(height: 16),
        _section(
            'Cuisines',
            restaurant.cuisines
                .map((cuisine) =>
                    AppConstants.cuisineNames[cuisine] ??
                    cuisine.replaceAll('_', ' '))
                .toList(),
            'Cuisine information not recorded.'),
        _section('Atmosphere', restaurant.vibeTags,
            'Atmosphere information not recorded.'),
        _section('Food highlights', restaurant.foodHighlights,
            'Food highlights not recorded.'),
        const Text('Offerings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (restaurant.offerings.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Offerings not recorded.'))
        else
          ...restaurant.offerings.map((offering) {
            final description = [
              offering['drink_type'],
              offering['brewing_method']
            ]
                .where((part) => part != null && part.toString().isNotEmpty)
                .join(' • ');
            final price = offering['price'];
            final provenance = [offering['source'], offering['checked_on']]
                .where((part) => part != null && part.toString().isNotEmpty)
                .join(' • ');
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(description.isEmpty ? 'Offering' : description),
              subtitle: provenance.isEmpty ? null : Text(provenance),
              trailing: Text(price == null
                  ? 'Price unknown'
                  : '${offering['currency'] ?? 'INR'} $price'),
            );
          }),
        const SizedBox(height: 16),
        _copyLink('Directions link', directions.toString()),
        if (website != null &&
            ['https', 'http'].contains(website.scheme) &&
            website.host.isNotEmpty)
          _copyLink('Website link', website.toString())
        else
          const Text('Website not recorded.'),
      ],
    );
  }

  Widget _section(String title, List<String> values, String empty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(values.isEmpty ? empty : values.join(' • ')),
      ]),
    );
  }

  Widget _copyLink(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            tooltip: 'Copy $label',
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$label copied.')));
            },
          ),
        ]),
        SelectableText(url, style: const TextStyle(color: AppTheme.secondary)),
      ]),
    );
  }
}
