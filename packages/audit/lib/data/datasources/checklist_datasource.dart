import '../../domain/entities/checklist_entity.dart';

class ChecklistDatasource {
  List<ChecklistEntity> getChecklistFor({
    required String isoTemplate,
    required String department,
  }) {
    final key = '${isoTemplate.trim()}|${department.trim()}';

    final Map<String, List<Map<String, String>>> _data = {
      'ISO 9001:2015|Warehouse': [
        {
          'title': 'Goods Receipt Procedure',
          'description': 'Ensure all incoming goods are received according to the standard operating procedure, including verification of purchase orders and delivery notes.',
        },
        {
          'title': 'Incoming Quality Inspection',
          'description': 'Inspect the quality of all incoming goods before storage, checking for damage, quantity accuracy, and conformance to specifications.',
        },
        {
          'title': 'Labeling & Product Identification',
          'description': 'Verify that all stored goods are clearly labeled with proper identification including product name, batch number, and expiry date if applicable.',
        },
        {
          'title': 'FIFO/FEFO Implementation',
          'description': 'Confirm that First In First Out or First Expired First Out principles are properly applied in the warehouse storage and retrieval process.',
        },
        {
          'title': 'Stock Record Accuracy',
          'description': 'Verify that physical stock counts match the recorded inventory data in the system, ensuring no discrepancies between actual and reported stock.',
        },
      ],

      'ISO 14001:2015|Warehouse': [
        {
          'title': 'Waste Segregation Compliance',
          'description': 'Ensure all waste materials are properly segregated according to category such as organic, inorganic, hazardous, and recyclable waste.',
        },
        {
          'title': 'Waste Management Practices',
          'description': 'Verify that cardboard, plastic, and other recyclable materials are managed and disposed of according to the environmental waste management procedure.',
        },
        {
          'title': 'Hazardous Material Storage',
          'description': 'Inspect the storage area for hazardous materials to ensure it meets safety standards including proper labeling, ventilation, and containment measures.',
        },
        {
          'title': 'Leakage & Contamination Prevention',
          'description': 'Check that no liquid leakage or environmental contamination is present in the warehouse, including inspection of storage containers and drainage areas.',
        },
        {
          'title': 'Separate Waste Bin Availability',
          'description': 'Confirm that clearly labeled separate waste bins are available and accessible throughout the warehouse for proper waste disposal by staff.',
        },
      ],

      'ISO 9001:2015|Production': [
        {
          'title': 'SOP Availability & Compliance',
          'description': 'Verify that standard operating procedures for production are available at workstations and that operators are following them correctly during production.',
        },
        {
          'title': 'Machine Condition & Readiness',
          'description': 'Inspect all production machines to confirm they are in proper working condition, calibrated, and have up-to-date maintenance records.',
        },
        {
          'title': 'In-Process Quality Control',
          'description': 'Confirm that quality control checks are being performed at defined intervals during the production process to catch defects early.',
        },
        {
          'title': 'Defective Product Handling',
          'description': 'Verify that defective or non-conforming products are properly identified, segregated, recorded, and handled according to the non-conformance procedure.',
        },
        {
          'title': 'Production Documentation Completeness',
          'description': 'Check that all required production records including batch records, inspection logs, and output reports are complete, accurate, and up to date.',
        },
      ],

      'ISO 14001:2015|Production': [
        {
          'title': 'Production Waste Management',
          'description': 'Verify that waste generated during production is properly collected, categorized, and disposed of in accordance with the environmental management plan.',
        },
        {
          'title': 'Emission Control',
          'description': 'Inspect emission sources such as exhaust pipes and ventilation systems to ensure smoke, gas, and dust levels are within acceptable environmental limits.',
        },
        {
          'title': 'Energy Efficiency Practices',
          'description': 'Confirm that energy-saving measures are implemented in the production area, including proper use of equipment and turning off machines when not in use.',
        },
        {
          'title': 'Wastewater Management',
          'description': 'Inspect wastewater discharge points and treatment systems to ensure liquid waste from production is properly treated before being released.',
        },
        {
          'title': 'Chemical Storage Safety',
          'description': 'Verify that all chemicals used in production are stored safely with proper labeling, material safety data sheets available, and spill containment measures in place.',
        },
      ],
    };

    final items = _data[key] ?? [];

    return items.map((item) => ChecklistEntity(
      title: item['title']!,
      description: item['description']!,
      category: department,
      isPassed: null,
      hasFinding: false,
    )).toList();
  }
}