import 'package:flutter/material.dart';
import 'package:slt_hire_log/extensions/rate_card_service.dart';
import 'package:slt_hire_log/models/rate_card_models.dart';
import 'package:slt_hire_log/screens/Calculator_Screen.dart';
import 'package:slt_hire_log/widgets/Price_Update_Dialog_Widget.dart';

class RateCardScreen extends StatefulWidget {
  const RateCardScreen({super.key});

  @override
  _RateCardScreenState createState() => _RateCardScreenState();
}

class _RateCardScreenState extends State<RateCardScreen> with SingleTickerProviderStateMixin {
  final RateCardService _rateCardService = RateCardService();
  late TabController _tabController;
  
  List<CalculatedRateCard> _rateCards = [];
  CalculatedRateCard? _selectedRateCard;
  Map<String, Map<String, Map<String, Map<String, List<RateCardSlab>>>>> _organizedSlabs = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRateCards();
  }

  Future<void> _loadRateCards() async {
    try {
      print("ggggg");
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final rateCards = await _rateCardService.getCalculatedRateCards();
      setState(() {
        _rateCards = rateCards;
        if (rateCards.isNotEmpty) {
          _selectedRateCard = rateCards.first;
          _loadSlabs();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSlabs() async {
    if (_selectedRateCard == null) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final organizedSlabs = await _rateCardService.getOrganizedSlabs(
        _selectedRateCard!.id,
        _tabController.index == 0 ? 'AFTER_2000' : 'BEFORE_2000'
      );
      
      setState(() {
        _organizedSlabs = organizedSlabs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
void showFuelPriceUpdateDialog(BuildContext context, {Function()? onSuccess}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => FuelPriceUpdateDialog(onSuccess: onSuccess),
  );
}
  void _onRateCardChanged(CalculatedRateCard? value) {
    if (value != null) {
      setState(() {
        _selectedRateCard = value;
      });
      _loadSlabs();
    }
  }

  void _onTabChanged() {
    if (_selectedRateCard != null) {
      _loadSlabs();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
       crossAxisAlignment: CrossAxisAlignment.end,
       mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // First FAB
          FloatingActionButton(
        
        backgroundColor: const Color.fromARGB(255, 6, 25, 131),
        foregroundColor: Colors.white,
  onPressed: () {
    showFuelPriceUpdateDialog(context, onSuccess: () {
      // Refresh data after update
      _loadRateCards();
    });
  },
  tooltip: 'Update Fuel Prices',
  
  child: Icon(Icons.edit),
),
          SizedBox(
            height: 16,
            width: 16), // spacing between buttons
          // Second FAB
          FloatingActionButton(
            heroTag: "fab2",
            tooltip: 'Calculate Prices',
             backgroundColor: const Color.fromARGB(255, 6, 25, 131),
        foregroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RentalCalculatorScreen()),
              );
            },
            child: Icon(Icons.settings),
          ),
        ],
      ),
    


      appBar: AppBar(
        
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          indicatorColor: const Color.fromARGB(255, 0, 26, 172),
          labelColor:const Color.fromARGB(255, 0, 26, 172) ,
          unselectedLabelColor: Colors.black,
          dividerColor: const Color.fromARGB(255, 21, 61, 170),
          controller: _tabController,
          onTap: (index) => _onTabChanged(),
          tabs: [
            Tab(text: 'AFTER 2000'),
            Tab(text: 'BEFORE 2000'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Rate Card Selection Dropdown
          SizedBox(height: 50,),
          Padding(
            padding: EdgeInsets.only(left: 16.0,right: 16.00,top: 30),
            child: DropdownButtonFormField<CalculatedRateCard>(
              
              initialValue: _selectedRateCard,
              items: _rateCards.map((card) {
                return DropdownMenuItem<CalculatedRateCard>(
                  value: card,
                  child: Text(
                    '${card.baseName} - ${card.calculationDate.toString().substring(0, 10)}',
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: _onRateCardChanged,
              decoration: InputDecoration(
                  
                labelText: 'Select Rate Card',
              enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      // Border when focused
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: const Color.fromARGB(255, 13, 0, 192), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
                border: OutlineInputBorder(
                  
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          
          // Fuel Price Info
          if (_selectedRateCard != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFuelPriceInfo('Diesel', _selectedRateCard!.newDieselPrice),
                  _buildFuelPriceInfo('Petrol', _selectedRateCard!.newPetrolPrice),
                ],
              ),
            ),
          
          // Content Area
          if (_isLoading)
            Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage.isNotEmpty)
          
            Expanded(child: Center(child: Text('Error: $_errorMessage')))
          else if (_organizedSlabs.isEmpty)
            Expanded(child: Center(child: Text('No rate card data available')))
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRateCardTab(),
                  _buildRateCardTab(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFuelPriceInfo(String fuelType, double price) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
       
      ),
      child: Column(
        children: [
          Text(fuelType, style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color: const Color.fromARGB(255, 3, 25, 150))),
          Text('Rs. ${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildRateCardTab() {
    return ListView(
      children: _organizedSlabs.entries.map((serviceEntry) {
        return Card(
          color: Colors.white,  
          margin: EdgeInsets.all(8.0),
          child: ExpansionTile(
            backgroundColor: Colors.white,
            title: Text(
              _getServiceTypeDisplayName(serviceEntry.key),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: serviceEntry.value.entries.map((categoryEntry) {
              return ExpansionTile(
                 backgroundColor: Colors.white,
                title: Text(
                  _getCategoryDisplayName(categoryEntry.key),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                children: categoryEntry.value.entries.map((fuelEntry) {
                  return ExpansionTile(
                     backgroundColor: Colors.white,
                    title: Text(
                      _getFuelTypeDisplayName(fuelEntry.key),
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    children: fuelEntry.value.entries.map((rateEntry) {
                      return _buildRateTable(rateEntry.value, rateEntry.key);
                    }).toList(),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRateTable(List<RateCardSlab> slabs, String rateType) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${rateType.toUpperCase()} Rates',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          DataTable(
            columnSpacing: 12,
            columns: [
              DataColumn(label: Text('KM Slab', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Monthly', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('Add. KM', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              if (slabs.any((s) => s.overtimeRate != null))
                DataColumn(label: Text('Overtime', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              if (slabs.any((s) => s.nightAllowance != null))
                DataColumn(label: Text('Night', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            ],
            rows: slabs.map((slab) {
              return DataRow(cells: [
                DataCell(Text(slab.kmSlab, style: TextStyle(fontSize: 12))),
                DataCell(Text(slab.monthlyRental?.toStringAsFixed(2) ?? '-', style: TextStyle(fontSize: 12))),
                DataCell(Text(slab.additionalKmRate?.toStringAsFixed(2) ?? '-', style: TextStyle(fontSize: 12))),
                if (slabs.any((s) => s.overtimeRate != null))
                  DataCell(Text(slab.overtimeRate?.toStringAsFixed(2) ?? '-', style: TextStyle(fontSize: 12))),
                if (slabs.any((s) => s.nightAllowance != null))
                  DataCell(Text(slab.nightAllowance?.toStringAsFixed(2) ?? '-', style: TextStyle(fontSize: 12))),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getServiceTypeDisplayName(String serviceType) {
    switch (serviceType) {
      case 'WITH_DRIVER_FUEL': return 'With Driver & Fuel';
      case 'WITHOUT_DRIVER_FUEL': return 'Without Driver & Fuel';
      case 'OVERNIGHT_PARKING': return 'Overnight Parking';
      case '24HOUR_DOUBLE_DRIVER': return '24 Hour Double Driver';
      case 'Short Term_WITH_DRIVER_FUEL': return 'Short Term With Driver';
      case 'Full time loaded with a Generator_WITH_DRIVER_FUEL': return 'Generator With Driver';
      case 'Full time loaded with a Generator_WITHOUT_DRIVER_F': return 'Generator Without Driver';
      default: return serviceType.replaceAll('_', ' ');
    }
  }

  String _getCategoryDisplayName(String categoryCode) {
    switch (categoryCode) {
      case 'CAR01': return 'Cars';
      case 'CAR02': return 'Cars (Type 2)';
      case 'VAN01': return 'Vans (Field Use)';
      case 'VAN02': return 'Passenger Vans';
      case 'DCAB01': return 'Double Cabs 2WD';
      case 'DCAB02': return 'Double Cabs 4WD';
      case 'DCAB03': return 'Double Cabs 4WD (Type 3)';
      default: return categoryCode;
    }
  }

  String _getFuelTypeDisplayName(String fuelType) {
    if (fuelType == 'NULL' || fuelType == 'GENERAL') return 'General';
    return fuelType;
  }
}