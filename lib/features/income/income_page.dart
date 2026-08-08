import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/settings_action.dart';
import 'widgets/daily_form.dart';
import 'widgets/due_persons_sheet.dart';
import 'widgets/eid_form.dart';
import 'widgets/general_donation_form.dart';
import 'widgets/jumma_form.dart';
import 'widgets/monthly_collection_form.dart';
import 'widgets/ramadan_form.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isMonthly = _tab.index == 2;
    final isPersonTab = _tab.index == 2 || _tab.index == 4;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navIncome),
        actions: [
          if (isPersonTab)
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              tooltip: l.managePeople,
              onPressed: () => context.push('/persons'),
            ),
          if (isMonthly)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: l.showDuePersons,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: false,
                builder: (_) => const DuePersonsSheet(),
              ),
            ),
          const SettingsAction(),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [
            Tab(text: l.incomeGeneral),
            Tab(text: l.incomeJumma),
            Tab(text: l.incomeMonthly),
            Tab(text: l.incomeEid),
            Tab(text: l.incomeRamadan),
            Tab(text: l.incomeDaily),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          GeneralDonationForm(),
          JummaForm(),
          MonthlyCollectionForm(),
          EidForm(),
          RamadanForm(),
          DailyForm(),
        ],
      ),
    );
  }
}
