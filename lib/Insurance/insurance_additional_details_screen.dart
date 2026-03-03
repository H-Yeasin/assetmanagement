import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'models/insurance_model.dart';

class InsuranceAdditionalDetailsScreen extends StatelessWidget {
  final InsurancePolicy policy;

  const InsuranceAdditionalDetailsScreen({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Insurance Details',
          style: TextStyle(
            color: Color(0xFF111111),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            const SizedBox(height: 16),
            if (policy.category == 'auto')
              ..._buildAutoGrid()
            else if (policy.category == 'personal')
              ..._buildPersonalGrid()
            else if (policy.category == 'home')
              ..._buildHomeGrid()
            else if (policy.category == 'appliance')
              ..._buildApplianceGrid()
            else if (policy.category == 'pet')
              ..._buildPetGrid()
            else
              ..._buildDefaultGrid(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAutoGrid() {
    return [
      _buildInfoCardWide(
        icon: Image.asset(
          'assets/images/insurance/car.png',
          width: 20,
          height: 20,
          errorBuilder: (c, e, s) => const Icon(
            Icons.directions_car,
            color: Color(0xFFFF9800),
            size: 20,
          ),
        ),
        bgColor: const Color(0xFFFFF7EA),
        label: 'Vehicle Model',
        value: policy.vehicleModel ?? policy.name,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/provider.png',
              bgColor: const Color(0xFFE3F2FD),
              label: 'Provider',
              value: policy.provider ?? 'N/A',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Renewal Date',
              value: policy.renewalDate != null
                  ? DateFormat('MMM dd, yyyy').format(policy.renewalDate!)
                  : 'N/A',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/premium.png',
              bgColor: const Color(0xFFFEF0F5),
              label: 'Premium',
              value: '\$${NumberFormat('#,##0').format(policy.premium)}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/coverage.png',
              bgColor: const Color(0xFFFFF0F0),
              label: 'Coverage',
              value: policy.coverageType ?? 'Comprehensive',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/timeleft,totalpayment,paymentdone,policynumber.png',
              bgColor: const Color(0xFFF1F8F1),
              label: 'Time Left',
              value: policy.timeLeft ?? 'N/A',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/timeleft,totalpayment,paymentdone,policynumber.png',
              bgColor: const Color(0xFFF1F8F1),
              label: 'Total Payment',
              value: policy.totalPayments?.toString() ?? 'N/A',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/timeleft,totalpayment,paymentdone,policynumber.png',
              bgColor: const Color(0xFFF1F8F1),
              label: 'Payment Done',
              value: policy.paymentsCompleted?.toString() ?? 'N/A',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/timeleft,totalpayment,paymentdone,policynumber.png',
              bgColor: const Color(0xFFF1F8F1),
              label: 'Policy Number',
              value: policy.policyNumber ?? 'N/A',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Start Date',
              value: policy.startDate != null
                  ? DateFormat('MMM dd, yyyy').format(policy.startDate!)
                  : 'N/A',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'End Date',
              value: policy.endDate != null
                  ? DateFormat('MMM dd, yyyy').format(policy.endDate!)
                  : 'N/A',
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildPersonalGrid() {
    return [
      _buildInfoCardWide(
        icon: const Icon(Icons.person, color: Color(0xFF4CAF50), size: 20),
        bgColor: const Color(0xFFF1F8F1),
        label: 'Policy Name',
        value: policy.name,
      ),
      const SizedBox(height: 12),
      _buildInfoCardWide(
        iconPath:
            'assets/images/insurance/timeleft,totalpayment,paymentdone,policynumber.png',
        bgColor: const Color(0xFFF1F8F1),
        label: 'Insurance Type',
        value: policy.personalInsuranceType ?? 'N/A',
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/premium.png',
              bgColor: const Color(0xFFFEF0F5),
              label: 'Premium',
              value: '\$${NumberFormat('#,##0').format(policy.premium)}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/provider.png',
              bgColor: const Color(0xFFE3F2FD),
              label: 'Provider',
              value: policy.provider ?? 'N/A',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Renewal Date',
              value: policy.renewalDate != null
                  ? DateFormat('MMM dd, yyyy').format(policy.renewalDate!)
                  : 'N/A',
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    ];
  }

  List<Widget> _buildHomeGrid() {
    return [
      _buildInfoCardWide(
        iconPath: 'assets/images/insurance/address.png',
        bgColor: const Color(0xFFFFF0F0),
        label: 'Address',
        value: policy.propertyAddress ?? 'N/A',
      ),
      const SizedBox(height: 12),
      _buildInfoCardWide(
        iconPath: 'assets/images/insurance/farmhouse.png',
        bgColor: const Color(0xFFE3F2FD),
        label: 'Home',
        value: policy.name,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/provider.png',
              bgColor: const Color(0xFFE3F2FD),
              label: 'Provider',
              value: policy.provider ?? 'N/A',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Renewal Date',
              value: policy.renewalDate != null
                  ? DateFormat('MMM dd, yyyy').format(policy.renewalDate!)
                  : 'N/A',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/premium.png',
              bgColor: const Color(0xFFFEF0F5),
              label: 'Payment',
              value: '\$${NumberFormat('#,##0').format(policy.premium)}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/coverage.png',
              bgColor: const Color(0xFFFFF0F0),
              label: 'Coverage',
              value: policy.coverageType ?? 'Comprehensive',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/timeleft,totalpayment,paymentdone,policynumber.png',
              bgColor: const Color(0xFFF1F8F1),
              label: 'Policy Number',
              value: policy.policyNumber ?? 'N/A',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Type',
              value: policy.paymentFrequency ?? 'Monthly',
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildApplianceGrid() {
    return [
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/appliance.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Appliance',
              value: policy.name,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/provider.png',
              bgColor: const Color(0xFFE3F2FD),
              label: 'Provider',
              value: policy.provider ?? 'N/A',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/timeleft,totalpayment,paymentdone,policynumber.png',
              bgColor: const Color(0xFFF1F8F1),
              label: 'Manufacturer',
              value: policy.manufacturer ?? 'Bosch',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Warranty',
              value: policy.renewalDate != null
                  ? DateFormat('MMM dd, yyyy').format(policy.renewalDate!)
                  : 'N/A',
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildPetGrid() {
    return [
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/petinsurance.png',
              bgColor: const Color(0xFFFFF7EA),
              label: 'Pet Name',
              value: policy.petName ?? policy.name,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/provider.png',
              bgColor: const Color(0xFFE3F2FD),
              label: 'Provider',
              value: policy.provider ?? 'N/A',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/timeleft,totalpayment,paymentdone,policynumber.png',
              bgColor: const Color(0xFFF1F8F1),
              label: 'Policy Number',
              value: policy.policyNumber ?? 'N/A',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Renewal Date',
              value: policy.renewalDate != null
                  ? DateFormat('MMM dd, yyyy').format(policy.renewalDate!)
                  : 'N/A',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/premium.png',
              bgColor: const Color(0xFFFEF0F5),
              label: 'Premium',
              value: '\$${NumberFormat('#,##0').format(policy.premium)}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/coverage.png',
              bgColor: const Color(0xFFFFF0F0),
              label: 'Coverage',
              value: policy.coverageType ?? 'Comprehensive',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Start date',
              value: policy.startDate != null
                  ? DateFormat('MMM dd, yyyy').format(policy.startDate!)
                  : 'N/A',
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    ];
  }

  List<Widget> _buildDefaultGrid() {
    return [
      _buildInfoCardWide(
        icon: const Icon(
          Icons.shield_outlined,
          color: Color(0xFFFF9800),
          size: 24,
        ),
        bgColor: const Color(0xFFFFF7EA),
        label: 'Policy Name',
        value: policy.name,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCardSmall(
              iconPath: 'assets/images/insurance/provider.png',
              bgColor: const Color(0xFFE3F2FD),
              label: 'Provider',
              value: policy.provider ?? 'N/A',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCardSmall(
              iconPath:
                  'assets/images/insurance/renewaldate,startdate,enddate.png',
              bgColor: const Color(0xFFF7F2FA),
              label: 'Renewal Date',
              value: policy.renewalDate != null
                  ? DateFormat('MMM dd, yyyy').format(policy.renewalDate!)
                  : 'N/A',
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildInfoCardWide({
    Widget? icon,
    String? iconPath,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Center(
              child:
                  icon ??
                  (iconPath != null
                      ? Image.asset(iconPath, width: 24, height: 24)
                      : const SizedBox()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardSmall({
    Widget? icon,
    String? iconPath,
    Color? iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Center(
              child:
                  icon ??
                  (iconPath != null
                      ? Image.asset(
                          iconPath,
                          width: 20,
                          height: 20,
                          color: iconColor,
                        )
                      : const SizedBox()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
