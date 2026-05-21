enum AppRole {
  owner('owner', 'Owner'),
  admin('admin', 'Admin'),
  accounts('accounts', 'Accounts'),
  sales('sales', 'Sales'),
  warehouse('warehouse', 'Warehouse'),
  staff('staff', 'Staff');

  const AppRole(this.value, this.label);

  final String value;
  final String label;

  static AppRole fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return AppRole.values.firstWhere(
      (role) => role.value == normalized,
      orElse: () => AppRole.staff,
    );
  }
}

enum AppUserStatus {
  active('active', 'Active'),
  disabled('disabled', 'Disabled');

  const AppUserStatus(this.value, this.label);

  final String value;
  final String label;

  static AppUserStatus fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return normalized == disabled.value ? disabled : active;
  }
}

class AppModules {
  const AppModules._();

  static const String dashboard = 'dashboard';
  static const String customers = 'customers';
  static const String customerWrite = 'customers.write';
  static const String vendors = 'vendors';
  static const String vendorWrite = 'vendors.write';
  static const String inventory = 'inventory';
  static const String productWrite = 'products.write';
  static const String invoices = 'invoices';
  static const String invoiceWrite = 'invoices.write';
  static const String purchases = 'purchases';
  static const String purchaseWrite = 'purchases.write';
  static const String expenses = 'expenses';
  static const String reports = 'reports';
  static const String userManagement = 'users.manage';
  static const String businessSettings = 'business.settings';
  static const String advancedErp = 'advanced.erp';
}

class RolePermissions {
  const RolePermissions._();

  static const Set<AppRole> managers = {AppRole.owner, AppRole.admin};

  static Set<AppRole> allowedRolesFor(String module) {
    return switch (module) {
      AppModules.dashboard => AppRole.values.toSet(),
      AppModules.customers => {
        AppRole.owner,
        AppRole.admin,
        AppRole.accounts,
        AppRole.sales,
        AppRole.staff,
      },
      AppModules.customerWrite => {
        AppRole.owner,
        AppRole.admin,
        AppRole.accounts,
        AppRole.sales,
      },
      AppModules.vendors => {
        AppRole.owner,
        AppRole.admin,
        AppRole.accounts,
        AppRole.warehouse,
      },
      AppModules.vendorWrite => {
        AppRole.owner,
        AppRole.admin,
        AppRole.accounts,
      },
      AppModules.inventory => {
        AppRole.owner,
        AppRole.admin,
        AppRole.warehouse,
        AppRole.staff,
      },
      AppModules.productWrite => {
        AppRole.owner,
        AppRole.admin,
        AppRole.warehouse,
      },
      AppModules.invoices => {
        AppRole.owner,
        AppRole.admin,
        AppRole.accounts,
        AppRole.sales,
        AppRole.staff,
      },
      AppModules.invoiceWrite => {
        AppRole.owner,
        AppRole.admin,
        AppRole.sales,
        AppRole.staff,
      },
      AppModules.purchases => {
        AppRole.owner,
        AppRole.admin,
        AppRole.accounts,
        AppRole.warehouse,
      },
      AppModules.purchaseWrite => {
        AppRole.owner,
        AppRole.admin,
        AppRole.accounts,
      },
      AppModules.expenses => {AppRole.owner, AppRole.admin, AppRole.accounts},
      AppModules.reports => {AppRole.owner, AppRole.admin, AppRole.accounts},
      AppModules.userManagement => managers,
      AppModules.businessSettings => managers,
      AppModules.advancedErp => {
        AppRole.owner,
        AppRole.admin,
        AppRole.accounts,
        AppRole.sales,
        AppRole.warehouse,
      },
      _ => managers,
    };
  }

  static bool canAccessModule(String role, String module) {
    return allowedRolesFor(module).contains(AppRole.fromValue(role));
  }

  static bool canManageUsers(String role) {
    return managers.contains(AppRole.fromValue(role));
  }
}
