import 'package:flutter/material.dart';
import 'app_controller.dart';

class AppStrings {
  static bool isAr(BuildContext context) =>
      AppController.instance.isArabic(context);

  static TextDirection direction(BuildContext context) =>
      isAr(context) ? TextDirection.rtl : TextDirection.ltr;

  // Global & Navigation
  static String appTitle(BuildContext context) =>
      isAr(context) ? 'دليل مستقبلي | Future Guide' : 'Future Guide';
  static String navHome(BuildContext context) =>
      isAr(context) ? 'الرئيسية' : 'Home';
  static String navUniversities(BuildContext context) =>
      isAr(context) ? 'الجامعات' : 'Universities';
  static String navScholarships(BuildContext context) =>
      isAr(context) ? 'المنح والفرص' : 'Scholarships & Ops';
  static String navProfile(BuildContext context) =>
      isAr(context) ? 'الحساب' : 'Account';
  static String pressAgainToExit(BuildContext context) =>
      isAr(context)
          ? 'اضغط رجوع مرة أخرى للخروج من التطبيق'
          : 'Press back again to exit the app';

  // Home Screen
  static String enterAverage(BuildContext context) =>
      isAr(context) ? 'أدخل معدلك' : 'Enter your average';
  static String selectTrack(BuildContext context) =>
      isAr(context) ? 'اختر فرع الدراسة' : 'Select study branch';
  static String trackScientific(BuildContext context) =>
      isAr(context) ? 'علمي' : 'Scientific';
  static String trackLiterary(BuildContext context) =>
      isAr(context) ? 'أدبي' : 'Literary';
  static String trackVocational(BuildContext context) =>
      isAr(context) ? 'مهني' : 'Vocational';
  static String search(BuildContext context) =>
      isAr(context) ? 'ابحث' : 'Search';
  static String availableUniversities(BuildContext context) =>
      isAr(context) ? 'جامعات متاحة' : 'Available Universities';
  static String matchingColleges(BuildContext context) =>
      isAr(context) ? 'كليات مطابقة لمعدلك' : 'Colleges matching your average';
  static String viewAll(BuildContext context) =>
      isAr(context) ? 'عرض الكل' : 'View All';
  static String latestPosts(BuildContext context) =>
      isAr(context) ? 'آخر المنشورات والأخبار' : 'Latest Posts & News';
  static String viewDetails(BuildContext context) =>
      isAr(context) ? 'عرض التفاصيل' : 'View details';
  static String recently(BuildContext context) =>
      isAr(context) ? 'منذ فترة' : 'Recently';
  static String enterAverageFirst(BuildContext context) =>
      isAr(context) ? 'من فضلك أدخل معدلك أولاً' : 'Please enter your average first';
  static String enterValidNumber(BuildContext context) =>
      isAr(context) ? 'من فضلك أدخل رقماً صحيحاً للمعدل' : 'Please enter a valid numeric average';
  static String noCollegesFound(BuildContext context) =>
      isAr(context) ? 'لم يتم العثور على كليات تناسب هذا المعدل حالياً' : 'No colleges found matching this average';
  static String errorFetching(BuildContext context) =>
      isAr(context) ? 'حدث خطأ أثناء جلب البيانات، يرجى المحاولة لاحقاً' : 'An error occurred while fetching data, please try again';

  // Universities Screen
  static String filterAll(BuildContext context) =>
      isAr(context) ? 'الكل' : 'All';
  static String filterGovernment(BuildContext context) =>
      isAr(context) ? 'حكومي' : 'Government';
  static String filterPrivate(BuildContext context) =>
      isAr(context) ? 'أهلي' : 'Private';
  static String governorate(BuildContext context) =>
      isAr(context) ? 'المحافظة' : 'Governorate';
  static String selectGovernorate(BuildContext context) =>
      isAr(context) ? 'اختر المحافظة' : 'Select Governorate';
  static String allGovernorates(BuildContext context) =>
      isAr(context) ? 'كافة المحافظات' : 'All Governorates';
  static String universityType(BuildContext context) =>
      isAr(context) ? 'نوع الجامعة' : 'University Type';
  static String governmentAndPrivate(BuildContext context) =>
      isAr(context) ? 'حكومي وأهلي' : 'Gov & Private';
  static String searchUniversityHint(BuildContext context) =>
      isAr(context) ? 'ابحث عن جامعة...' : 'Search for a university...';
  static String noUniversitiesFound(BuildContext context) =>
      isAr(context) ? 'لا توجد جامعات مطابقة للبحث' : 'No universities match your search';
  static String loginToFavoriteUni(BuildContext context) =>
      isAr(context)
          ? 'يرجى تسجيل الدخول لحفظ الجامعات في المفضلة'
          : 'Please log in to save universities to your favorites';
  static String loginToFavoriteOpp(BuildContext context) =>
      isAr(context)
          ? 'يرجى تسجيل الدخول لحفظ الفرص والمنح'
          : 'Please log in to save opportunities and scholarships';

  // University Details
  static String tabPosts(BuildContext context) =>
      isAr(context) ? 'منشورات' : 'Posts';
  static String tabColleges(BuildContext context) =>
      isAr(context) ? 'الكليات والأقسام' : 'Colleges & Depts';
  static String tabAbout(BuildContext context) =>
      isAr(context) ? 'عن الجامعة' : 'About';
  static String tabPhotos(BuildContext context) =>
      isAr(context) ? 'صور' : 'Photos';
  static String visitWebsite(BuildContext context) =>
      isAr(context) ? 'زيارة الموقع الرسمي' : 'Visit Official Website';
  static String websiteNotAvailable(BuildContext context) =>
      isAr(context) ? 'رابط الموقع الرسمي غير متوفر' : 'Official website link not available';
  static String major(BuildContext context) =>
      isAr(context) ? 'التخصص' : 'Major';

  static String minAverage(BuildContext context) =>
      isAr(context) ? 'الحد الأدنى للمعدل' : 'Minimum Average';

  // Scholarships & Opportunities
  static String scholarshipsTitle(BuildContext context) =>
      isAr(context) ? 'المنح الدراسية' : 'Scholarships';
  static String opportunitiesTitle(BuildContext context) =>
      isAr(context) ? 'الفرص والفعاليات' : 'Opportunities & Events';
  static String scholarshipsSubtitle(BuildContext context) =>
      isAr(context)
          ? 'كل الفرص اللي تحتاجها في مكان واحد، سواء منح أو فعاليات.'
          : 'All the opportunities you need in one place, whether scholarships or events.';
  static String applicationDeadline(BuildContext context) =>
      isAr(context) ? 'آخر موعد للتقديم' : 'Application Deadline';
  static String registrationLink(BuildContext context) =>
      isAr(context) ? 'رابط التسجيل والتقديم' : 'Registration & Application Link';
  static String shareOpportunity(BuildContext context) =>
      isAr(context) ? 'مشاركة الفرصة' : 'Share Opportunity';
  static String saveOpportunity(BuildContext context) =>
      isAr(context) ? 'حفظ الفرصة' : 'Save Opportunity';
  static String saved(BuildContext context) =>
      isAr(context) ? 'محفوظة' : 'Saved';
  static String linkNotAvailable(BuildContext context) =>
      isAr(context) ? 'رابط التسجيل غير متوفر' : 'Registration link not available';

  // Profile & Guest Screen
  static String profile(BuildContext context) =>
      isAr(context) ? 'الملف الشخصي' : 'Profile';
  static String guestMode(BuildContext context) =>
      isAr(context) ? 'وضع الزائر' : 'Guest Mode';
  static String welcomeToGuide(BuildContext context) =>
      isAr(context) ? 'مرحباً بك في دليل مستقبلي 🎓' : 'Welcome to Future Guide 🎓';
  static String guestPromptDesc(BuildContext context) =>
      isAr(context)
          ? 'سجّل الدخول أو أنشئ حساباً جديداً للوصول إلى ميزاتك الأكاديمية وحفظ مفضلاتك ومتابعة آخر الفرص.'
          : 'Log in or create a new account to access your academic features, save favorites, and track latest opportunities.';
  static String loginOrRegister(BuildContext context) =>
      isAr(context) ? 'تسجيل الدخول / إنشاء حساب' : 'Log In / Create Account';
  static String whyCreateAccount(BuildContext context) =>
      isAr(context) ? 'مميزات إنشاء الحساب' : 'Account Features';
  static String featFavUnis(BuildContext context) =>
      isAr(context) ? 'حفظ الجامعات المفضلة' : 'Save Favorite Universities';
  static String featFavUnisDesc(BuildContext context) =>
      isAr(context)
          ? 'احفظ الجامعات والكليات التي تهمك للرجوع إليها ومقارنتها بسهولة.'
          : 'Bookmark universities and colleges that interest you to compare easily.';
  static String featOpp(BuildContext context) =>
      isAr(context) ? 'متابعة المنح والفرص' : 'Track Scholarships & Ops';
  static String featOppDesc(BuildContext context) =>
      isAr(context)
          ? 'احفظ المنح الدراسية والفعاليات وتابع مواعيد التقديم المهمة.'
          : 'Save scholarships and events and stay updated with important deadlines.';
  static String featCustomize(BuildContext context) =>
      isAr(context) ? 'تخصيص البحث والمعدل' : 'Personalize Search & Average';
  static String featCustomizeDesc(BuildContext context) =>
      isAr(context)
          ? 'احفظ معدلك ومسارك الدراسي لعرض الكليات المناسبة لك تلقائياً.'
          : 'Save your GPA and study track to automatically view eligible colleges.';
  static String favUniversities(BuildContext context) =>
      isAr(context) ? 'الجامعات المفضلة' : 'Favorite Universities';
  static String noFavUniversities(BuildContext context) =>
      isAr(context) ? 'لم تقم بإضافة أي جامعة للمفضلة بعد' : 'No universities added to favorites yet';
  static String savedOpportunities(BuildContext context) =>
      isAr(context) ? 'الفرص المحفوظة' : 'Saved Opportunities';
  static String noSavedOpportunities(BuildContext context) =>
      isAr(context) ? 'لم تقم بحفظ أي فرصة بعد' : 'No opportunities saved yet';
  static String editAccountSettings(BuildContext context) =>
      isAr(context) ? 'إعدادات الحساب' : 'Account Settings';
  static String logOut(BuildContext context) =>
      isAr(context) ? 'تسجيل الخروج' : 'Log Out';
  static String loggedOutSuccess(BuildContext context) =>
      isAr(context) ? 'تم تسجيل الخروج بنجاح' : 'Logged out successfully';
  static String userNotFound(BuildContext context) =>
      isAr(context) ? 'لم يتم العثور على بيانات المستخدم' : 'User data not found';
  static String trackLabel(BuildContext context, String track, double avg) =>
      isAr(context) ? 'مسار $track • $avg%' : 'Track: $track • $avg%';

  // Account Settings Screen
  static String fullName(BuildContext context) =>
      isAr(context) ? 'الاسم الكامل' : 'Full Name';
  static String schoolAverage(BuildContext context) =>
      isAr(context) ? 'المعدل الدراسي' : 'Academic Average';
  static String studyBranch(BuildContext context) =>
      isAr(context) ? 'فرع الدراسة' : 'Study Branch';
  static String saveChanges(BuildContext context) =>
      isAr(context) ? 'حفظ التعديلات' : 'Save Changes';

  // Login & Sign Up Screen
  static String login(BuildContext context) =>
      isAr(context) ? 'تسجيل الدخول' : 'Log In';
  static String signUp(BuildContext context) =>
      isAr(context) ? 'إنشاء حساب جديد' : 'Create New Account';
  static String welcomeBack(BuildContext context) =>
      isAr(context) ? 'مرحباً بك مجدداً' : 'Welcome back';
  static String startJourney(BuildContext context) =>
      isAr(context) ? 'ابدأ رحلتك الأكاديمية الآن' : 'Start your academic journey now';
  static String email(BuildContext context) =>
      isAr(context) ? 'البريد الإلكتروني' : 'Email Address';
  static String password(BuildContext context) =>
      isAr(context) ? 'كلمة المرور' : 'Password';
  static String confirmSignUp(BuildContext context) =>
      isAr(context) ? 'تأكيد وإنشاء الحساب' : 'Confirm & Create Account';
  static String dontHaveAccount(BuildContext context) =>
      isAr(context) ? 'ليس لديك حساب؟ سجل الآن' : "Don't have an account? Sign up";
  static String alreadyHaveAccount(BuildContext context) =>
      isAr(context) ? 'لديك حساب بالفعل؟ سجل الدخول' : 'Already have an account? Log in';
  static String browseAsGuest(BuildContext context) =>
      isAr(context) ? 'تصفح كزائر' : 'Browse as Guest';
  static String enterEmailAndPassword(BuildContext context) =>
      isAr(context) ? 'من فضلك أدخل البريد الإلكتروني وكلمة المرور' : 'Please enter email and password';
  static String fullNameRequired(BuildContext context) =>
      isAr(context) ? 'الاسم الكامل مطلوب لإنشاء حساب جديد' : 'Full name is required to create an account';
  static String signInWithGoogle(BuildContext context) =>
      isAr(context) ? 'تسجيل الدخول باستخدام Google' : 'Sign in with Google';
  static String signUpWithGoogle(BuildContext context) =>
      isAr(context) ? 'إنشاء حساب باستخدام Google' : 'Sign up with Google';
  static String orDivider(BuildContext context) =>
      isAr(context) ? 'أو' : 'OR';

  // Settings Screen
  static String settings(BuildContext context) =>
      isAr(context) ? 'الإعدادات' : 'Settings';
  static String language(BuildContext context) =>
      isAr(context) ? 'اللغة' : 'Language';
  static String appearance(BuildContext context) =>
      isAr(context) ? 'المظهر' : 'Appearance';
  static String privacyPolicy(BuildContext context) =>
      isAr(context) ? 'سياسة الخصوصية' : 'Privacy Policy';
  static String contactSupport(BuildContext context) =>
      isAr(context) ? 'التواصل مع الدعم' : 'Contact Support';
  static String chooseLanguage(BuildContext context) =>
      isAr(context) ? 'اختر اللغة' : 'Choose Language';
  static String chooseAppearance(BuildContext context) =>
      isAr(context) ? 'اختر المظهر' : 'Choose Appearance';
  static String langArabic(BuildContext context) =>
      'العربية (Arabic)';
  static String langArabicSub(BuildContext context) =>
      isAr(context) ? 'اللغة الافتراضية للتطبيق' : 'Default app language';
  static String langEnglish(BuildContext context) =>
      'English (الإنجليزية)';
  static String langEnglishSub(BuildContext context) =>
      isAr(context) ? 'اللغة الإنجليزية' : 'English language';
  static String langSystem(BuildContext context) =>
      isAr(context) ? 'تلقائي (لغة الجهاز)' : 'System Default';
  static String themeLight(BuildContext context) =>
      isAr(context) ? 'الوضع الفاتح' : 'Light Mode';
  static String themeDark(BuildContext context) =>
      isAr(context) ? 'الوضع الداكن' : 'Dark Mode';
  static String themeSystem(BuildContext context) =>
      isAr(context) ? 'تلقائي (حسب إعدادات الجهاز)' : 'System Default';
  static String supportTeamDesc(BuildContext context) =>
      isAr(context)
          ? 'فريق دعم دليل مستقبلي جاهز لمساعدتك والإجابة على كافة استفساراتك.'
          : 'Future Guide support team is here to help and answer all your inquiries.';
  static String emailSupport(BuildContext context) =>
      isAr(context) ? 'البريد الإلكتروني' : 'Email Support';
  static String sendNote(BuildContext context) =>
      isAr(context) ? 'إرسال ملاحظة أو اقتراح' : 'Send Note or Suggestion';
  static String sendNoteSub(BuildContext context) =>
      isAr(context) ? 'شاركنا برأيك لتطوير التطبيق' : 'Share your thoughts to improve the app';
  static String writeNoteHint(BuildContext context) =>
      isAr(context) ? 'اكتب ملاحظتك أو اقتراحك هنا...' : 'Type your note or suggestion here...';
  static String cancel(BuildContext context) =>
      isAr(context) ? 'إلغاء' : 'Cancel';
  static String send(BuildContext context) =>
      isAr(context) ? 'إرسال' : 'Send';
  static String noteSentSuccess(BuildContext context) =>
      isAr(context) ? 'شكراً لملاحظتك! تم الإرسال بنجاح.' : 'Thank you for your feedback! Sent successfully.';
  static String privacyPolicyTerms(BuildContext context) =>
      isAr(context) ? 'شروط الاستخدام وأمان البيانات' : 'Terms of use & data protection';
  static String supportSubtitle(BuildContext context) =>
      isAr(context) ? 'المساعدة والاستفسارات والملاحظات' : 'Help, inquiries & feedback';
  static String openPrivacyPolicyLink(BuildContext context) =>
      isAr(context) ? 'فتح سياسة الخصوصية الرسمية' : 'Open Official Privacy Policy';
  static String version(BuildContext context) =>
      isAr(context) ? 'الإصدار 2.0.0' : 'Version 2.0.0';
}
