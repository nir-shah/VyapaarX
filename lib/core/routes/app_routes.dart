import 'package:flutter/material.dart';

import '../../core/constants/app_roles.dart';
import '../../screens/advanced/advanced_erp_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/business/business_setup_screen.dart';
import '../../screens/customers/add_edit_customer_screen.dart';
import '../../screens/customers/customer_detail_screen.dart';
import '../../screens/customers/customer_list_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/expenses/add_expense_screen.dart';
import '../../screens/expenses/expense_list_screen.dart';
import '../../screens/invoices/create_invoice_screen.dart';
import '../../screens/invoices/invoice_detail_screen.dart';
import '../../screens/invoices/invoice_list_screen.dart';
import '../../screens/products/add_edit_product_screen.dart';
import '../../screens/products/product_detail_screen.dart';
import '../../screens/products/product_list_screen.dart';
import '../../screens/purchases/create_purchase_invoice_screen.dart';
import '../../screens/purchases/purchase_invoice_detail_screen.dart';
import '../../screens/purchases/purchase_invoice_list_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/settings/business_settings_screen.dart';
import '../../screens/settings/theme_selection_screen.dart';
import '../../screens/staff/admin_user_management_screen.dart';
import '../../screens/vendors/add_edit_vendor_screen.dart';
import '../../screens/vendors/vendor_detail_screen.dart';
import '../../screens/vendors/vendor_list_screen.dart';
import '../../models/customer_model.dart';
import '../../models/expense_model.dart';
import '../../models/product_model.dart';
import '../../models/purchase_invoice_model.dart';
import '../../models/sales_invoice_model.dart';
import '../../models/vendor_model.dart';
import '../../widgets/auth_guard.dart';
import '../../widgets/role_guard.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String businessSetup = '/business-setup';
  static const String customers = '/customers';
  static const String customerAdd = '/customers/add';
  static const String customerEdit = '/customers/edit';
  static const String customerDetail = '/customers/detail';
  static const String inventory = '/inventory';
  static const String productAdd = '/products/add';
  static const String productEdit = '/products/edit';
  static const String productDetail = '/products/detail';
  static const String vendors = '/vendors';
  static const String vendorAdd = '/vendors/add';
  static const String vendorEdit = '/vendors/edit';
  static const String vendorDetail = '/vendors/detail';
  static const String invoices = '/invoices';
  static const String invoiceCreate = '/invoices/create';
  static const String invoiceDetail = '/invoices/detail';
  static const String purchaseInvoices = '/purchase-invoices';
  static const String purchaseCreate = '/purchase-invoices/create';
  static const String purchaseDetail = '/purchase-invoices/detail';
  static const String expenses = '/expenses';
  static const String expenseAdd = '/expenses/add';
  static const String expenseEdit = '/expenses/edit';
  static const String reports = '/reports';
  static const String adminUsers = '/admin/users';
  static const String advancedErp = '/advanced-erp';
  static const String payments = '/payments';
  static const String settings = '/settings';
  static const String themeSelection = '/theme-selection';

  static const List<String> navigationShellRoutes = [
    dashboard,
    invoices,
    invoiceCreate,
    invoiceDetail,
    customers,
    customerAdd,
    customerEdit,
    customerDetail,
    inventory,
    productAdd,
    productEdit,
    productDetail,
    vendors,
    vendorAdd,
    vendorEdit,
    vendorDetail,
    purchaseInvoices,
    purchaseCreate,
    purchaseDetail,
    expenses,
    expenseAdd,
    expenseEdit,
    reports,
    adminUsers,
    advancedErp,
    settings,
    themeSelection,
  ];

  static bool usesNavigationShell(String? routeName) {
    return navigationShellRoutes.contains(routeName);
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      home || splash => _materialRoute(const SplashScreen(), settings),
      login => _materialRoute(const LoginScreen(), settings),
      otp => _materialRoute(
        OtpScreen(phoneNumber: settings.arguments as String? ?? ''),
        settings,
      ),
      businessSetup => _materialRoute(
        const AuthGuard(child: BusinessSetupScreen()),
        settings,
      ),
      dashboard => _materialRoute(
        _protected(const DashboardScreen(), module: AppModules.dashboard),
        settings,
      ),
      customers => _materialRoute(
        _protected(const CustomerListScreen(), module: AppModules.customers),
        settings,
      ),
      customerAdd => _materialRoute(
        _protected(
          const AddEditCustomerScreen(),
          module: AppModules.customerWrite,
        ),
        settings,
      ),
      customerEdit => _materialRoute(
        _protected(
          AddEditCustomerScreen(customer: settings.arguments as CustomerModel?),
          module: AppModules.customerWrite,
        ),
        settings,
      ),
      customerDetail => _materialRoute(
        _customerDetailRoute(settings),
        settings,
      ),
      inventory => _materialRoute(
        _protected(const ProductListScreen(), module: AppModules.inventory),
        settings,
      ),
      productAdd => _materialRoute(
        _protected(
          const AddEditProductScreen(),
          module: AppModules.productWrite,
        ),
        settings,
      ),
      productEdit => _materialRoute(
        _protected(
          AddEditProductScreen(product: settings.arguments as ProductModel?),
          module: AppModules.productWrite,
        ),
        settings,
      ),
      productDetail => _materialRoute(_productDetailRoute(settings), settings),
      vendors => _materialRoute(
        _protected(const VendorListScreen(), module: AppModules.vendors),
        settings,
      ),
      vendorAdd => _materialRoute(
        _protected(const AddEditVendorScreen(), module: AppModules.vendorWrite),
        settings,
      ),
      vendorEdit => _materialRoute(
        _protected(
          AddEditVendorScreen(vendor: settings.arguments as VendorModel?),
          module: AppModules.vendorWrite,
        ),
        settings,
      ),
      vendorDetail => _materialRoute(_vendorDetailRoute(settings), settings),
      invoices => _materialRoute(
        _protected(const InvoiceListScreen(), module: AppModules.invoices),
        settings,
      ),
      invoiceCreate => _materialRoute(
        _protected(
          const CreateInvoiceScreen(),
          module: AppModules.invoiceWrite,
        ),
        settings,
      ),
      invoiceDetail => _materialRoute(_invoiceDetailRoute(settings), settings),
      purchaseInvoices => _materialRoute(
        _protected(
          const PurchaseInvoiceListScreen(),
          module: AppModules.purchases,
        ),
        settings,
      ),
      purchaseCreate => _materialRoute(
        _protected(
          const CreatePurchaseInvoiceScreen(),
          module: AppModules.purchaseWrite,
        ),
        settings,
      ),
      purchaseDetail => _materialRoute(
        _purchaseDetailRoute(settings),
        settings,
      ),
      expenses => _materialRoute(
        _protected(const ExpenseListScreen(), module: AppModules.expenses),
        settings,
      ),
      expenseAdd => _materialRoute(
        _protected(const AddExpenseScreen(), module: AppModules.expenses),
        settings,
      ),
      expenseEdit => _materialRoute(
        _protected(
          AddExpenseScreen(expense: settings.arguments as ExpenseModel?),
          module: AppModules.expenses,
        ),
        settings,
      ),
      reports => _materialRoute(
        _protected(const ReportsScreen(), module: AppModules.reports),
        settings,
      ),
      adminUsers => _materialRoute(
        _protected(
          const AdminUserManagementScreen(),
          module: AppModules.userManagement,
        ),
        settings,
      ),
      advancedErp => _materialRoute(
        _protected(const AdvancedErpScreen(), module: AppModules.advancedErp),
        settings,
      ),
      AppRoutes.settings => _materialRoute(
        _protected(
          const BusinessSettingsScreen(),
          module: AppModules.businessSettings,
        ),
        settings,
      ),
      themeSelection => _materialRoute(
        _protected(
          const ThemeSelectionScreen(),
          module: AppModules.businessSettings,
        ),
        settings,
      ),
      _ => _materialRoute(
        _RouteNotFoundScreen(routeName: settings.name),
        settings,
      ),
    };
  }

  static MaterialPageRoute<T> _materialRoute<T>(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<T>(builder: (_) => child, settings: settings);
  }

  static Widget _protected(Widget child, {required String module}) {
    return AuthGuard(
      child: RoleGuard(module: module, child: child),
    );
  }

  static Widget _customerDetailRoute(RouteSettings settings) {
    final customer = settings.arguments;
    if (customer is! CustomerModel) {
      return _RouteNotFoundScreen(routeName: settings.name);
    }
    return _protected(
      CustomerDetailScreen(customer: customer),
      module: AppModules.customers,
    );
  }

  static Widget _vendorDetailRoute(RouteSettings settings) {
    final vendor = settings.arguments;
    if (vendor is! VendorModel) {
      return _RouteNotFoundScreen(routeName: settings.name);
    }
    return _protected(
      VendorDetailScreen(vendor: vendor),
      module: AppModules.vendors,
    );
  }

  static Widget _productDetailRoute(RouteSettings settings) {
    final product = settings.arguments;
    if (product is! ProductModel) {
      return _RouteNotFoundScreen(routeName: settings.name);
    }
    return _protected(
      ProductDetailScreen(product: product),
      module: AppModules.inventory,
    );
  }

  static Widget _invoiceDetailRoute(RouteSettings settings) {
    final invoice = settings.arguments;
    if (invoice is! SalesInvoiceModel) {
      return _RouteNotFoundScreen(routeName: settings.name);
    }
    return _protected(
      InvoiceDetailScreen(invoice: invoice),
      module: AppModules.invoices,
    );
  }

  static Widget _purchaseDetailRoute(RouteSettings settings) {
    final invoice = settings.arguments;
    if (invoice is! PurchaseInvoiceModel) {
      return _RouteNotFoundScreen(routeName: settings.name);
    }
    return _protected(
      PurchaseInvoiceDetailScreen(invoice: invoice),
      module: AppModules.purchases,
    );
  }
}

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No route configured for ${routeName ?? 'unknown route'}.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
