// Bundled service definitions, not workers or marketplace activity.
// Canonical source: supabase/migrations/202610090002_catalog.sql.
// A regression test checks every UUID, label, skill and question against that seed.
import 'dart:convert';
import '../models/marketplace_models.dart';

List<Map<String, dynamic>> bundledProfessionRows() =>
    (jsonDecode(_bundledCatalogJson) as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

List<Profession> loadBundledProfessionCatalog() =>
    List.unmodifiable(bundledProfessionRows().map(Profession.fromJson));

const _bundledCatalogJson = r'''
[
  {
    "id": "10000000-0000-4000-8000-000000000001",
    "category": "Construction",
    "name": "Mazdoor",
    "name_ur": "مزدور",
    "skills": [
      "General Labourer",
      "Construction Helper",
      "Material Handling",
      "Site Cleaning"
    ],
    "questions": [
      {
        "key": "role",
        "label": "Construction role",
        "type": "select",
        "required": true,
        "options": [
          "Labourer",
          "Helper",
          "Team leader"
        ]
      },
      {
        "key": "work_types",
        "label": "Types of work",
        "type": "multiselect",
        "required": true,
        "options": [
          "Material handling",
          "Digging",
          "Concrete mixing",
          "Site cleaning"
        ]
      },
      {
        "key": "team",
        "label": "Can join a team",
        "type": "boolean",
        "required": false
      }
    ],
    "sort_order": 1
  },
  {
    "id": "10000000-0000-4000-8000-000000000002",
    "category": "Construction",
    "name": "Mason",
    "name_ur": "مستری",
    "skills": [
      "Brickwork",
      "Plastering",
      "Concrete Work",
      "Boundary Walls"
    ],
    "questions": [
      {
        "key": "work_types",
        "label": "Masonry specializations",
        "type": "multiselect",
        "required": true,
        "options": [
          "Brickwork",
          "Plastering",
          "Concrete work",
          "Boundary walls"
        ]
      },
      {
        "key": "team",
        "label": "Can bring helpers",
        "type": "boolean",
        "required": false
      }
    ],
    "sort_order": 2
  },
  {
    "id": "10000000-0000-4000-8000-000000000003",
    "category": "Electrical Services",
    "name": "Electrician",
    "name_ur": "الیکٹریشن",
    "skills": [
      "Wiring Repair",
      "Wiring Installation",
      "Fault Finding",
      "Switchboard Installation",
      "Solar Wiring"
    ],
    "questions": [
      {
        "key": "setting",
        "label": "Work settings",
        "type": "multiselect",
        "required": true,
        "options": [
          "Residential",
          "Commercial",
          "Industrial"
        ]
      },
      {
        "key": "services",
        "label": "Electrical capabilities",
        "type": "multiselect",
        "required": true,
        "options": [
          "Wiring",
          "Installation",
          "Troubleshooting",
          "Switchboards",
          "Solar wiring"
        ]
      },
      {
        "key": "qualification",
        "label": "Relevant qualifications (optional)",
        "type": "text",
        "required": false
      }
    ],
    "sort_order": 3
  },
  {
    "id": "10000000-0000-4000-8000-000000000004",
    "category": "Plumbing Services",
    "name": "Plumber",
    "name_ur": "پلمبر",
    "skills": [
      "Leakage Repair",
      "Pipe Installation",
      "Bathroom Installation",
      "Kitchen Plumbing",
      "Drain Cleaning"
    ],
    "questions": [
      {
        "key": "services",
        "label": "Plumbing services",
        "type": "multiselect",
        "required": true,
        "options": [
          "Pipe installation",
          "Leakage repair",
          "Bathroom installation",
          "Kitchen installation",
          "Drain cleaning"
        ]
      },
      {
        "key": "emergency",
        "label": "Offers emergency appointments",
        "type": "boolean",
        "required": false
      }
    ],
    "sort_order": 4
  },
  {
    "id": "10000000-0000-4000-8000-000000000005",
    "category": "Home Services",
    "name": "Painter",
    "name_ur": "پینٹر",
    "skills": [
      "Interior Painting",
      "Exterior Painting",
      "Surface Preparation",
      "Spray Painting",
      "Wall Finishing"
    ],
    "questions": [
      {
        "key": "setting",
        "label": "Painting work",
        "type": "multiselect",
        "required": true,
        "options": [
          "Interior",
          "Exterior",
          "Both"
        ]
      },
      {
        "key": "techniques",
        "label": "Specializations",
        "type": "multiselect",
        "required": false,
        "options": [
          "Surface preparation",
          "Spray painting",
          "Texture finishing",
          "Wood finishing"
        ]
      }
    ],
    "sort_order": 5
  },
  {
    "id": "10000000-0000-4000-8000-000000000006",
    "category": "Home Services",
    "name": "Carpenter",
    "name_ur": "بڑھئی",
    "skills": [
      "Furniture Repair",
      "Doors and Windows",
      "Kitchen Cabinets",
      "Custom Furniture"
    ],
    "questions": [
      {
        "key": "materials",
        "label": "Materials worked with",
        "type": "multiselect",
        "required": true,
        "options": [
          "Solid wood",
          "Plywood",
          "MDF",
          "Laminates"
        ]
      }
    ],
    "sort_order": 6
  },
  {
    "id": "10000000-0000-4000-8000-000000000007",
    "category": "Construction",
    "name": "Welder",
    "name_ur": "ویلڈر",
    "skills": [
      "Gate Fabrication",
      "Grills and Railings",
      "Metal Repair",
      "Steel Structures"
    ],
    "questions": [
      {
        "key": "methods",
        "label": "Welding methods",
        "type": "multiselect",
        "required": true,
        "options": [
          "Arc welding",
          "MIG",
          "TIG",
          "Gas welding"
        ]
      }
    ],
    "sort_order": 7
  },
  {
    "id": "10000000-0000-4000-8000-000000000008",
    "category": "Construction",
    "name": "Tile Installer",
    "name_ur": "ٹائل لگانے والا",
    "skills": [
      "Floor Tiles",
      "Wall Tiles",
      "Bathroom Tiling",
      "Tile Repair"
    ],
    "questions": [
      {
        "key": "materials",
        "label": "Tile materials",
        "type": "multiselect",
        "required": true,
        "options": [
          "Ceramic",
          "Porcelain",
          "Marble",
          "Granite"
        ]
      }
    ],
    "sort_order": 8
  },
  {
    "id": "10000000-0000-4000-8000-000000000009",
    "category": "Appliance Services",
    "name": "AC Technician",
    "name_ur": "اے سی ٹیکنیشن",
    "skills": [
      "AC Installation",
      "AC Repair",
      "AC Servicing",
      "Refrigerator Repair"
    ],
    "questions": [
      {
        "key": "services",
        "label": "Technician services",
        "type": "multiselect",
        "required": true,
        "options": [
          "Installation",
          "Repair",
          "Maintenance"
        ]
      },
      {
        "key": "equipment",
        "label": "Supported equipment",
        "type": "multiselect",
        "required": true,
        "options": [
          "Split AC",
          "Window AC",
          "Inverter AC",
          "Refrigerator",
          "Freezer"
        ]
      }
    ],
    "sort_order": 9
  },
  {
    "id": "10000000-0000-4000-8000-000000000010",
    "category": "Home Services",
    "name": "Cleaner",
    "name_ur": "صفائی کرنے والا",
    "skills": [
      "House Cleaning",
      "Deep Cleaning",
      "Office Cleaning",
      "Water Tank Cleaning"
    ],
    "questions": [
      {
        "key": "supplies",
        "label": "Brings cleaning supplies",
        "type": "boolean",
        "required": false
      },
      {
        "key": "settings",
        "label": "Cleaning settings",
        "type": "multiselect",
        "required": true,
        "options": [
          "Homes",
          "Offices",
          "Shops",
          "Water tanks"
        ]
      }
    ],
    "sort_order": 10
  },
  {
    "id": "10000000-0000-4000-8000-000000000011",
    "category": "Outdoor Services",
    "name": "Gardener",
    "name_ur": "مالی",
    "skills": [
      "Garden Maintenance",
      "Lawn Care",
      "Planting",
      "Tree Pruning"
    ],
    "questions": [
      {
        "key": "tools",
        "label": "Brings gardening tools",
        "type": "boolean",
        "required": false
      }
    ],
    "sort_order": 11
  },
  {
    "id": "10000000-0000-4000-8000-000000000012",
    "category": "Appliance Services",
    "name": "Appliance Repair Technician",
    "name_ur": "گھریلو آلات کی مرمت",
    "skills": [
      "Washing Machine Repair",
      "Oven Repair",
      "Water Pump Repair",
      "Small Appliance Repair"
    ],
    "questions": [
      {
        "key": "appliances",
        "label": "Supported appliances",
        "type": "multiselect",
        "required": true,
        "options": [
          "Washing machines",
          "Ovens",
          "Water pumps",
          "Small appliances"
        ]
      }
    ],
    "sort_order": 12
  },
  {
    "id": "10000000-0000-4000-8000-000000000013",
    "category": "Home Services",
    "name": "Domestic Helper",
    "name_ur": "گھریلو مددگار",
    "skills": [
      "Household Help",
      "Cooking",
      "Laundry",
      "Part Time Help"
    ],
    "questions": [
      {
        "key": "tasks",
        "label": "Household tasks offered",
        "type": "multiselect",
        "required": true,
        "options": [
          "Household cleaning",
          "Cooking",
          "Laundry",
          "Ironing"
        ]
      },
      {
        "key": "schedule",
        "label": "Preferred work arrangement",
        "type": "select",
        "required": true,
        "options": [
          "Part time",
          "Full time",
          "Occasional"
        ]
      }
    ],
    "sort_order": 13
  },
  {
    "id": "10000000-0000-4000-8000-000000000014",
    "category": "Electrical Services",
    "name": "Solar Technician",
    "name_ur": "سولر ٹیکنیشن",
    "skills": [
      "Solar Installation",
      "Panel Cleaning",
      "Inverter Maintenance",
      "Solar Fault Finding"
    ],
    "questions": [
      {
        "key": "systems",
        "label": "Systems supported",
        "type": "multiselect",
        "required": true,
        "options": [
          "On grid",
          "Off grid",
          "Hybrid"
        ]
      }
    ],
    "sort_order": 14
  },
  {
    "id": "10000000-0000-4000-8000-000000000015",
    "category": "Home Services",
    "name": "Pest Control Technician",
    "name_ur": "کیڑوں کا خاتمہ",
    "skills": [
      "Termite Treatment",
      "Cockroach Control",
      "General Pest Control"
    ],
    "questions": [
      {
        "key": "services",
        "label": "Treatments offered",
        "type": "multiselect",
        "required": true,
        "options": [
          "Termites",
          "Cockroaches",
          "General pests"
        ]
      },
      {
        "key": "qualification",
        "label": "Relevant training (optional)",
        "type": "text",
        "required": false
      }
    ],
    "sort_order": 15
  },
  {
    "id": "10000000-0000-4000-8000-000000000016",
    "category": "Learning Services",
    "name": "Tutor",
    "name_ur": "استاد",
    "skills": [
      "Primary Subjects",
      "Mathematics",
      "English",
      "Science",
      "Computer Skills"
    ],
    "questions": [
      {
        "key": "levels",
        "label": "Levels taught",
        "type": "multiselect",
        "required": true,
        "options": [
          "Primary",
          "Middle",
          "Secondary",
          "College",
          "Adult learning"
        ]
      }
    ],
    "sort_order": 16
  },
  {
    "id": "10000000-0000-4000-8000-000000000017",
    "category": "Personal Services",
    "name": "Beautician",
    "name_ur": "بیوٹیشن",
    "skills": [
      "Hair Styling",
      "Makeup",
      "Skin Care",
      "Bridal Services"
    ],
    "questions": [
      {
        "key": "setting",
        "label": "Service setting",
        "type": "select",
        "required": true,
        "options": [
          "At customer location",
          "At salon",
          "Both"
        ]
      }
    ],
    "sort_order": 17
  },
  {
    "id": "10000000-0000-4000-8000-000000000018",
    "category": "Other Services",
    "name": "Other Local Service",
    "name_ur": "دیگر مقامی خدمات",
    "skills": [
      "Other Local Service"
    ],
    "questions": [
      {
        "key": "service",
        "label": "Describe your service",
        "type": "text",
        "required": true
      }
    ],
    "sort_order": 99
  }
]
''';
