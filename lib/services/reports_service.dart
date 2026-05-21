import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/customer_model.dart';
import '../models/expense_model.dart';
import '../models/product_model.dart';
import '../models/sales_invoice_model.dart';
import '../models/vendor_model.dart';

enum ReportDateFilter {
  today,
  thisMonth,
  last30Days,
  thisYear,
  allTime;

  String get label {
    return switch (this) {
      ReportDateFilter.today => 'Today',
      ReportDateFilter.thisMonth => 'This month',
      ReportDateFilter.last30Days => 'Last 30 days',
      ReportDateFilter.thisYear => 'This year',
      ReportDateFilter.allTime => 'All time',
    };
  }

  ReportDateRange range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      ReportDateFilter.today => ReportDateRange(today, today.add(days1)),
      ReportDateFilter.thisMonth => ReportDateRange(
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      ),
      ReportDateFilter.last30Days => ReportDateRange(
        today.subtract(days29),
        today.add(days1),
      ),
      ReportDateFilter.thisYear => ReportDateRange(
        DateTime(now.year),
        DateTime(now.year + 1),
      ),
      ReportDateFilter.allTime => const ReportDateRange(null, null),
    };
  }
}

const days1 = Duration(days: 1);
const days29 = Duration(days: 29);

class ReportDateRange {
  const ReportDateRange(this.start, this.end);

  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime? value) {
    if (start == null && end == null) return true;
    if (value == null) return false;
    final afterStart = start == null || !value.isBefore(start!);
    final beforeEnd = end == null || value.isBefore(end!);
    return afterStart && beforeEnd;
  }
}

class ReportsData {
  const ReportsData({
    required this.filter,
    required this.dailySales,
    required this.monthlySales,
    required this.filteredSales,
    required this.filteredInvoiceCount,
    required this.outstandingCustomerAmount,
    required this.outstandingCustomerCount,
    required this.vendorPayableAmount,
    required this.vendorPayableCount,
    required this.lowStockProducts,
    required this.filteredExpenseTotal,
    required this.filteredExpenseCount,
    required this.grossProfitEstimate,
    required this.netProfitEstimate,
    required this.topExpenseCategory,
  });

  final ReportDateFilter filter;
  final double dailySales;
  final double monthlySales;
  final double filteredSales;
  final int filteredInvoiceCount;
  final double outstandingCustomerAmount;
  final int outstandingCustomerCount;
  final double vendorPayableAmount;
  final int vendorPayableCount;
  final List<ProductModel> lowStockProducts;
  final double filteredExpenseTotal;
  final int filteredExpenseCount;
  final double grossProfitEstimate;
  final double netProfitEstimate;
  final String? topExpenseCategory;

  int get lowStockCount => lowStockProducts.length;

  bool get hasAnyData {
    return filteredInvoiceCount > 0 ||
        outstandingCustomerCount > 0 ||
        vendorPayableCount > 0 ||
        lowStockCount > 0 ||
        filteredExpenseCount > 0;
  }
}

class ReportsService {
  ReportsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<ReportsData> loadReports({
    required String businessId,
    required ReportDateFilter filter,
  }) async {
    if (businessId.trim().isEmpty) {
      throw ArgumentError('businessId is required to load reports.');
    }

    final snapshots = await Future.wait([
      _businessCollection(FirestoreCollections.salesInvoices, businessId).get(),
      _businessCollection(FirestoreCollections.customers, businessId).get(),
      _businessCollection(FirestoreCollections.vendors, businessId).get(),
      _businessCollection(FirestoreCollections.products, businessId).get(),
      _businessCollection(FirestoreCollections.expenses, businessId).get(),
    ]);

    final invoices = snapshots[0].docs
        .map(SalesInvoiceModel.fromDoc)
        .where((invoice) => invoice.businessId == businessId)
        .toList();
    final customers = snapshots[1].docs
        .map(CustomerModel.fromDoc)
        .where((customer) => customer.businessId == businessId)
        .toList();
    final vendors = snapshots[2].docs
        .map(VendorModel.fromDoc)
        .where((vendor) => vendor.businessId == businessId)
        .toList();
    final products = snapshots[3].docs
        .map(ProductModel.fromDoc)
        .where((product) => product.businessId == businessId)
        .toList();
    final expenses = snapshots[4].docs
        .map(ExpenseModel.fromDoc)
        .where((expense) => expense.businessId == businessId)
        .toList();

    final now = DateTime.now();
    final selectedRange = filter.range(now);
    final todayRange = ReportDateFilter.today.range(now);
    final monthRange = ReportDateFilter.thisMonth.range(now);

    final selectedInvoices = invoices
        .where((invoice) => selectedRange.contains(invoice.createdAt))
        .toList();
    final selectedExpenses = expenses
        .where((expense) => selectedRange.contains(expense.date))
        .toList();
    final lowStockProducts =
        products.where((product) => product.isLowStock).toList()..sort(
          (left, right) => (left.stockQuantity - left.lowStockLimit).compareTo(
            right.stockQuantity - right.lowStockLimit,
          ),
        );

    final purchasePriceByProductId = {
      for (final product in products) product.id: product.purchasePrice,
    };
    final filteredCostOfGoods = _estimateCostOfGoods(
      selectedInvoices,
      purchasePriceByProductId,
    );
    final filteredSales = _sumInvoices(selectedInvoices);
    final filteredExpenseTotal = _sumExpenses(selectedExpenses);
    final outstandingCustomers = customers
        .where((customer) => customer.outstanding > 0)
        .toList();
    final payableVendors = vendors
        .where((vendor) => vendor.outstandingPayable > 0)
        .toList();

    return ReportsData(
      filter: filter,
      dailySales: _sumInvoices(
        invoices.where((invoice) => todayRange.contains(invoice.createdAt)),
      ),
      monthlySales: _sumInvoices(
        invoices.where((invoice) => monthRange.contains(invoice.createdAt)),
      ),
      filteredSales: filteredSales,
      filteredInvoiceCount: selectedInvoices.length,
      outstandingCustomerAmount: outstandingCustomers.fold<double>(
        0,
        (total, customer) => total + customer.outstanding,
      ),
      outstandingCustomerCount: outstandingCustomers.length,
      vendorPayableAmount: payableVendors.fold<double>(
        0,
        (total, vendor) => total + vendor.outstandingPayable,
      ),
      vendorPayableCount: payableVendors.length,
      lowStockProducts: lowStockProducts.take(8).toList(),
      filteredExpenseTotal: filteredExpenseTotal,
      filteredExpenseCount: selectedExpenses.length,
      grossProfitEstimate: filteredSales - filteredCostOfGoods,
      netProfitEstimate:
          filteredSales - filteredCostOfGoods - filteredExpenseTotal,
      topExpenseCategory: _topExpenseCategory(selectedExpenses),
    );
  }

  Query<Map<String, dynamic>> _businessCollection(
    String collection,
    String businessId,
  ) {
    return _firestore
        .collection(collection)
        .where(FirestoreFields.businessId, isEqualTo: businessId);
  }

  double _sumInvoices(Iterable<SalesInvoiceModel> invoices) {
    return invoices.fold<double>(
      0,
      (total, invoice) => total + invoice.totalAmount,
    );
  }

  double _sumExpenses(Iterable<ExpenseModel> expenses) {
    return expenses.fold<double>(0, (total, expense) => total + expense.amount);
  }

  double _estimateCostOfGoods(
    Iterable<SalesInvoiceModel> invoices,
    Map<String, double> purchasePriceByProductId,
  ) {
    var total = 0.0;
    for (final invoice in invoices) {
      for (final item in invoice.items) {
        total +=
            item.quantity * (purchasePriceByProductId[item.productId] ?? 0);
      }
    }
    return total;
  }

  String? _topExpenseCategory(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return null;

    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final sorted = totals.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return sorted.first.key;
  }
}
