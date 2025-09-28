import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_algorithms/edgemax_speakers_autolayout/edgemax_speakers_autolayout.dart';

/// EdgeMax Speaker Layout Widget
/// 
/// A Flutter widget that provides a user interface for the EdgeMax speaker
/// auto-placement algorithm. This widget uses the EdgeMax library from fusion_lib
/// to calculate optimal speaker placements in rectangular rooms.
/// 
/// All measurements are in meters (m).
class EdgeMaxSpeakerLayoutWidget extends StatefulWidget {
  const EdgeMaxSpeakerLayoutWidget({super.key});

  @override
  State<EdgeMaxSpeakerLayoutWidget> createState() => _EdgeMaxSpeakerLayoutWidgetState();
}

class _EdgeMaxSpeakerLayoutWidgetState extends State<EdgeMaxSpeakerLayoutWidget> {
  final TextEditingController _lengthController = TextEditingController(text: '7.0');
  final TextEditingController _widthController = TextEditingController(text: '4.0');
  final TextEditingController _ceilingHeightController = TextEditingController(text: '3.0');
  final TextEditingController _listenerHeightController = TextEditingController(text: '1.2');
  
  EdgeMaxPlacementResult? _result;
  List<String> _validationErrors = <String>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculatePlacement(); // Calculate on widget load
  }

  void _calculatePlacement() async {
    setState(() {
      _isLoading = true;
      _validationErrors.clear();
    });

    try {
      final double length = double.parse(_lengthController.text);
      final double width = double.parse(_widthController.text);
      final double ceilingHeight = double.parse(_ceilingHeightController.text);
      final double listenerHeight = double.parse(_listenerHeightController.text);

      // Simulate processing delay for better UX
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final RectangularRoom room = RectangularRoom(
        length: length,
        width: width,
        ceilingHeight: ceilingHeight,
        listenerHeight: listenerHeight,
      );
      
      final EdgeMaxPlacementResult result = EdgeMaxSpeakerPlacementService.calculateCompleteResult(room);

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _validationErrors = <String>['Invalid input: Please enter valid numbers'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EdgeMax Speaker Layout'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Input Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.input, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'Room Parameters',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildInputField(
                            controller: _lengthController,
                            label: 'Length (m)',
                            icon: Icons.straighten,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            controller: _widthController,
                            label: 'Width (m)', 
                            icon: Icons.width_normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildInputField(
                            controller: _ceilingHeightController,
                            label: 'Ceiling Height (m)',
                            icon: Icons.height,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            controller: _listenerHeightController,
                            label: 'Listener Height (m)',
                            icon: Icons.person,
                          ),
                        ),
                      ],
                    ),
                    
                    if (_validationErrors.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _validationErrors.map((String error) => 
                            Row(
                              children: <Widget>[
                                const Icon(Icons.error, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Text(error, style: const TextStyle(color: Colors.red)),
                              ],
                            )
                          ).toList(),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _calculatePlacement,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calculate),
                        label: Text(_isLoading ? 'Calculating...' : 'Calculate Placement'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Results Section
            if (_result != null) ...<Widget>[
              // Room Layout Visualization - Featured prominently!
              Card(
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.view_in_ar, color: Colors.teal, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Room Layout with Speaker Icons',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(child: _buildRoomVisualization()),
                    ],
                  ),
                ),
              ),
              
              // Summary Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.summarize, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Placement Summary',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: <Widget>[
                            _buildSummaryRow('Total Speakers', '${_result!.summary.totalSpeakers}'),
                            _buildSummaryRow('EM90 Speakers', '${_result!.summary.em90Count}'),
                            _buildSummaryRow('EM180 Speakers', '${_result!.summary.em180Count}'),
                            _buildSummaryRow('EM-LP90 Speakers', '${_result!.summary.emlp90Count}'),
                            _buildSummaryRow('EM-LP180 Speakers', '${_result!.summary.emlp180Count}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Speaker Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.place, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            'Speaker Details (${_result!.placements.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Placements list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _result!.placements.length,
                        itemBuilder: (BuildContext context, int index) {
                          final SpeakerPlacement placement = _result!.placements[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            decoration: BoxDecoration(
                              color: _getSpeakerColor(placement.speakerType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getSpeakerColor(placement.speakerType).withOpacity(0.3),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getSpeakerColor(placement.speakerType),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                placement.speakerType,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text('Location: ${placement.location}'),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Position: (${placement.position.x.toStringAsFixed(2)}, '
                                    '${placement.position.y.toStringAsFixed(2)})',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                _getSpeakerIcon(placement.speakerType),
                                color: _getSpeakerColor(placement.speakerType),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Calculation Details Section  
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.info_outline, color: Colors.blue),
                  title: const Text('Calculation Details'),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: _result!.calculationDetails.entries
                              .map((MapEntry<String, dynamic> entry) => 
                                  _buildDetailRow(entry.key, entry.value.toString()))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoomVisualization() {
    if (_result == null) return const SizedBox.shrink();

    final double roomLength = double.tryParse(_lengthController.text) ?? 10.0;
    final double roomWidth = double.tryParse(_widthController.text) ?? 8.0;
    
    // Calculate scaling for visual representation (fit in 450x350 box for better detail)
    const double maxVisualWidth = 450.0;
    const double maxVisualHeight = 350.0;
    
    final double aspectRatio = roomLength / roomWidth;
    double visualWidth, visualHeight;
    
    if (aspectRatio > maxVisualWidth / maxVisualHeight) {
      visualWidth = maxVisualWidth;
      visualHeight = maxVisualWidth / aspectRatio;
    } else {
      visualHeight = maxVisualHeight;
      visualWidth = maxVisualHeight * aspectRatio;
    }
    
    final double scaleX = visualWidth / roomLength;
    final double scaleY = visualHeight / roomWidth;

    return Container(
      width: visualWidth + 180, // More padding for enhanced layout
      height: visualHeight + 160, // More padding for controls and legend
      child: Stack(
        children: <Widget>[
          // Enhanced Room Background with Grid
          Positioned(
            left: 80,
            top: 50,
            child: Container(
              width: visualWidth,
              height: visualHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                  ],
                ),
                border: Border.all(color: Colors.brown.shade800, width: 5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  // Room Corner Markers
                  ..._buildCornerMarkers(visualWidth, visualHeight),
                  
                  // Center Point Indicator
                  Positioned(
                    left: visualWidth / 2 - 4,
                    top: visualHeight / 2 - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                  
                  // Enhanced Speaker Positions
                  ..._result!.placements.asMap().entries.map((MapEntry<int, SpeakerPlacement> entry) {
                    final int index = entry.key;
                    final SpeakerPlacement placement = entry.value;
                    
                    final double visualX = placement.position.x * scaleX;
                    final double visualY = placement.position.y * scaleY;
                    
                    return _buildEnhancedSpeaker(
                      index: index,
                      placement: placement,
                      visualX: visualX,
                      visualY: visualY,
                      containerWidth: visualWidth,
                      containerHeight: visualHeight,
                    );
                  }).toList(),
                  
                  // Coverage Area Indicators (optional)
                  ..._buildCoverageAreas(scaleX, scaleY),
                ],
              ),
            ),
          ),
          
          // Enhanced Room Dimension Labels
          ..._buildEnhancedDimensionLabels(roomLength, roomWidth, visualWidth, visualHeight),
          
          // Coordinate System
          _buildCoordinateSystem(visualWidth, visualHeight),
        ],
      ),
    );
  }

  Widget _buildEnhancedSpeaker({
    required int index,
    required SpeakerPlacement placement,
    required double visualX,
    required double visualY,
    required double containerWidth,
    required double containerHeight,
  }) {
    return Stack(
      children: <Widget>[
        // Speaker Coverage Circle (subtle background)
        Positioned(
          left: visualX - 35,
          top: visualY - 35,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getSpeakerColor(placement.speakerType).withOpacity(0.1),
              border: Border.all(
                color: _getSpeakerColor(placement.speakerType).withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
        // Main Speaker Icon
        Positioned(
          left: visualX - 25,
          top: visualY - 25,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: <Color>[
                  _getSpeakerColor(placement.speakerType).withOpacity(0.9),
                  _getSpeakerColor(placement.speakerType),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: _getSpeakerColor(placement.speakerType).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getSpeakerIcon(placement.speakerType),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        // Enhanced Speaker Label - dynamically positioned to stay visible
        Positioned(
          left: (visualX + 120 > containerWidth) ? visualX - 120 : visualX + 30, // Avoid going off-screen right
          top: (visualY - 50 < 0) ? visualY + 30 : visualY - 50, // Avoid going off-screen top
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  _getSpeakerColor(placement.speakerType),
                  _getSpeakerColor(placement.speakerType).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  placement.speakerType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Coordinate Display - positioned directly below speaker icon to avoid overlap
        Positioned(
          left: visualX - 30, // Center under the speaker icon
          top: visualY + 35, // Always below the speaker icon
          child: Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white38, width: 0.5),
            ),
            child: Text(
              '(${placement.position.x.toStringAsFixed(1)},${placement.position.y.toStringAsFixed(1)})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCornerMarkers(double width, double height) {
    const double markerSize = 12.0;
    return <Widget>[
      // Top-left corner
      Positioned(
        left: 0,
        top: 0,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(6),
            ),
          ),
        ),
      ),
      // Top-right corner
      Positioned(
        right: 0,
        top: 0,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
            ),
          ),
        ),
      ),
      // Bottom-left corner
      Positioned(
        left: 0,
        bottom: 0,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6),
            ),
          ),
        ),
      ),
      // Bottom-right corner
      Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildCoverageAreas(double scaleX, double scaleY) {
    // Simplified coverage areas - you could enhance this based on actual coverage calculations
    return _result!.placements.map((SpeakerPlacement placement) {
      final double visualX = placement.position.x * scaleX;
      final double visualY = placement.position.y * scaleY;
      final double coverageRadius = placement.speakerType.contains('180') ? 60.0 : 45.0;
      
      return Positioned(
        left: visualX - coverageRadius,
        top: visualY - coverageRadius,
        child: Container(
          width: coverageRadius * 2,
          height: coverageRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getSpeakerColor(placement.speakerType).withOpacity(0.05),
            border: Border.all(
              color: _getSpeakerColor(placement.speakerType).withOpacity(0.2),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEnhancedDimensionLabels(
    double roomLength,
    double roomWidth,
    double visualWidth,
    double visualHeight,
  ) {
    return <Widget>[
      // Top dimension label with enhanced styling
      Positioned(
        top: 10,
        left: 80 + visualWidth / 2 - 60,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Colors.brown.shade700, Colors.brown.shade600],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.straighten, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Length: ${roomLength.toStringAsFixed(1)}m',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      // Left dimension label with enhanced styling
      Positioned(
        left: 10,
        top: 50 + visualHeight / 2 - 20,
        child: RotatedBox(
          quarterTurns: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Colors.brown.shade700, Colors.brown.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.width_normal, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Width: ${roomWidth.toStringAsFixed(1)}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildCoordinateSystem(double visualWidth, double visualHeight) {
    return Positioned(
      left: 80,
      top: 50,
      child: Container(
        width: visualWidth,
        height: visualHeight,
        child: Stack(
          children: <Widget>[
            // Origin marker (0,0)
            Positioned(
              left: -8,
              top: -8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }







  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label, 
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isTotal ? Colors.green : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value, 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTotal ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              key.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpeakerColor(String speakerType) {
    switch (speakerType) {
      case 'EM90':
      case 'EM-LP90':
        return Colors.blue;
      case 'EM180':
      case 'EM-LP180':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getSpeakerIcon(String speakerType) {
    switch (speakerType) {
      case 'EM90':
      case 'EM-LP90':
        return Icons.volume_up; // Directional speaker icon
      case 'EM180':
      case 'EM-LP180':
        return Icons.surround_sound; // Wide coverage speaker
      default:
        return Icons.speaker;
    }
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _ceilingHeightController.dispose();
    _listenerHeightController.dispose();
    super.dispose();
  }
}
