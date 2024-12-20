import 'package:account/service/database_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../model/event_detail_model.dart';
import '../model/chart_model.dart';
import 'package:account/constant.dart';

class AccountingService extends ChangeNotifier {
  final DatabaseService databaseService = DatabaseService.instance;
  String title = "";
  AccountingTypes type = AccountingTypes.nil;
  DateTime _date = DateTime.now();
  List<EventDetailModel> events = [];

  void setAccountingType(AccountingTypes type) {
    this.type = type;
    notifyListeners();
  }

  get accountType => type;

  List<ChartData> getChartData() {
    final monthlyExpense = getMonthlyExpense().abs();
    final monthlyIncome = getMonthlyIncome();
    return [
      ChartData('Expenses', monthlyExpense, Colors.red),
      ChartData('Income', monthlyIncome, Colors.green),
    ];
  }

  Future<void> addNewEvent({
    required double amount,
    required CalModes mode,
  }) async {
    try {
      inspectEventPara(amount: amount);
    } catch (e) {
      throw Exception(e);
    }
    try {
      await databaseService.insert(
        eventDetailModel: EventDetailModel(
          title: title,
          amount: mode == CalModes.income ? amount : -amount,
          date: _date,
          type: type,
        ),
      );
      await initAccountingService();
      notifyListeners();
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> initAccountingService() async {
    events = await databaseService.getEvents();
  }

  Future<void> deleteEvent({required int id}) async {
    await databaseService.delete(id: id);
    await initAccountingService();
    notifyListeners();
  }

  double getMonthlyExpense() {
    final now = DateTime.now();
    double sum = 0;
    for (var event in events) {
      if (event.date.month == now.month && event.date.year == now.year) {
        if (event.amount > 0) {
          continue;
        } else {
          sum += event.amount;
        }
      }
    }
    return sum;
  }

  double getMonthlyIncome() {
    final now = DateTime.now();
    double sum = 0;
    for (var event in events) {
      if (event.date.month == now.month && event.date.year == now.year) {
        if (event.amount < 0) {
          continue;
        } else {
          sum += event.amount;
        }
      }
    }
    return sum;
  }

  List<EventDetailModel> getEventsThisMonth() {
    final now = DateTime.now();
    final thisMonth = now.month;
    final thisYear = now.year;
    return events
        .where((element) =>
            element.date.month == thisMonth && element.date.year == thisYear)
        .toList();
  }

  double getMonthlyBalance() {
    return getMonthlyIncome() + getMonthlyExpense();
  }

  Map<String, List<EventDetailModel>> getEventsGroupedByDate() {
    final eventsByDate = <String, List<EventDetailModel>>{};

    for (var event in events) {
      final dateKey = DateFormat('yyyy/MM/dd EEEE').format(event.date);
      if (eventsByDate.containsKey(dateKey)) {
        eventsByDate[dateKey]!.add(event);
      } else {
        eventsByDate[dateKey] = [event];
      }
    }
    return eventsByDate;
  }

  List<String> getDates() {
    final List<String> sortedKeys = getEventsGroupedByDate().keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return sortedKeys;
  }

  void setTitle(String title) {
    this.title = title;
    print(title);
    notifyListeners();
  }

  void setDate(DateTime date) {
    _date = date;
  }

  void reset() {
    title = "";
    _date = DateTime.now();
    notifyListeners();
  }

  void inspectEventPara({required double amount}) {
    if (title == "") {
      throw Exception("Title is empty");
    }
    if (amount == 0) {
      throw Exception("Amount is 0");
    }
    if (type == AccountingTypes.nil) {
      throw Exception("Type is nil");
    }
  }
}
