class AppConstants {
  // Default API endpoint
  static const String defaultEmulatorApiUrl = 'http://10.0.2.2:8000';
  static const String defaultLocalhostApiUrl = 'http://localhost:8000';
  static const String defaultWifiApiUrl = 'http://192.168.83.100:8000';
  
  static const String appTitle = 'Food RecSys';
  static const String appSubtitle = 'Spotify for Food • UPI Dining Intelligence';

  // Real Dining Profile ID
  static const String defaultUserId = 'user_my_real_data';
  static const String userDisplayName = 'My Dining Profile';

  // Cuisine display mapping
  static const Map<String, String> cuisineNames = {
    'south_indian': 'South Indian',
    'biryani': 'Biryani',
    'mughlai': 'Mughlai & Awadhi',
    'cafe_western': 'Café & Coffee',
    'bakery': 'Bakery & Bakes',
    'street_food': 'Street Food & Chaat',
    'pizza': 'Pizza',
    'burger': 'Burgers & Wraps',
    'chinese_indo': 'Indo-Chinese',
    'north_indian_curry': 'North Indian',
    'tea_coffee': 'Chai & Beverages',
    'dessert': 'Desserts',
    'healthy': 'Salads & Healthy Bowls',
    'italian': 'Italian Pastas',
  };

  // Meal types
  static const List<String> mealOptions = [
    'any',
    'breakfast',
    'lunch',
    'snack',
    'dinner',
  ];

  // Areas in Lucknow
  static const List<String> areaOptions = [
    'All Areas',
    'Hazratganj',
    'Gomti Nagar',
    'Sushant Golf City',
    'Aliganj',
    'Indira Nagar',
    'Aminabad',
    'Chowk',
  ];

  // Sample SMS for manual testing
  static const Map<String, String> sampleSms = {
    'Swiggy': 'Your Swiggy order from The Belgian Waffle Co of Rs 280 is placed! Track live.',
    'Zomato': 'Order placed! Your meal from Dastarkhwan worth Rs 680 is being prepared. Track on Zomato.',
    'HDFC': 'Sent Rs.340.00 from HDFC Bank A/C **1234 to ROASTERY COFFEE HOUSE on 24-OCT-26 via UPI Ref 429812456789.',
    'SBI': 'Dear SBI UPI User, your A/c ending with 5678 debited by Rs.120.00 on 24Oct26 by SAGAR RATNA (UPI Ref no 429812112233)',
    'ICICI': 'ICICI Bank Acct XX789 debited with Rs 450.00 on 24-Oct-26. UPI:THE HAZELNUT FACTORY@okhdfcbank. Ref:429899001122.',
    'Axis': 'Axis Bank: INR 280.00 debited from A/C 9876 to CHAI POINT on 24-10-2026 via UPI. Ref 998877665544.',
    'IndusInd': 'IndusInd Bank: INR 350.00 debited from A/c XX1234 on 24-10-26 to MOTI MAHAL. UPI Ref 429811002299.',
  };
}
