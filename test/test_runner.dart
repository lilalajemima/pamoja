import 'presentation/blocs/auth/auth_bloc_test.dart' as auth_bloc_test;
import 'presentation/blocs/opportunities/opportunities_bloc_test.dart' as opportunities_bloc_test;
import 'presentation/blocs/tracker/tracker_bloc_test.dart' as tracker_bloc_test;
import 'presentation/blocs/theme/theme_cubit_test.dart' as theme_cubit_test;

// Presentation Widgets Tests
import 'presentation/widgets/opportunity_card_test.dart' as opportunity_card_test;
import 'presentation/widgets/activity_card_test.dart' as activity_card_test;
import 'presentation/widgets/category_chip_test.dart' as category_chip_test;
import 'presentation/widgets/skill_chip_test.dart' as skill_chip_test;

// Domain Models Tests
import 'domain/models/opportunity_test.dart' as opportunity_test;
import 'domain/models/volunteer_activity_test.dart' as volunteer_activity_test;
import 'domain/models/community_post_test.dart' as community_post_test;
import 'domain/models/notification_model_test.dart' as notification_model_test;
import 'domain/models/user_profile_test.dart' as user_profile_test;

// Core Services Tests
import 'core/services/notification_service_test.dart' as notification_service_test;

void main() {
  // Presentation Blocs
  auth_bloc_test.main();
  opportunities_bloc_test.main();
  tracker_bloc_test.main();
  theme_cubit_test.main();
  
  // Presentation Widgets
  opportunity_card_test.main();
  activity_card_test.main();
  category_chip_test.main();
  skill_chip_test.main();
  
  // Domain Models
  opportunity_test.main();
  volunteer_activity_test.main();
  community_post_test.main();
  notification_model_test.main();
  user_profile_test.main();
  
  // Core Services
  notification_service_test.main();
}