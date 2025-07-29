import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quote.dart';
import '../models/client.dart';
import '../models/item.dart';
import '../providers/quote_provider.dart';
import '../providers/client_provider.dart';
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';

class QuoteFormScreen extends StatefulWidget {
  final Quote? quote;

  const QuoteFormScreen({super.key, this.quote});

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quoteNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _quoteDate = DateTime.now();
  DateTime? _expiryDate;
  Client? _selectedClient;
  String _status = 'draft';
  double _taxRate = 0.0;
  List<QuoteItem> _quoteItems = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
      context.read<ItemProvider>().loadItems();
      
      // Initialize form with quote data after providers are set up
      if (widget.quote != null) {
        _initializeFromQuote(widget.quote!);
        _findAndSetSelectedClient();
      }
    });
  }

  void _initializeFromQuote(Quote quote) {
    _quoteNumberController.text = quote.quoteNumber;
    _quoteDate = quote.quoteDate;
    _expiryDate = quote.expiryDate;
    _status = quote.status;
    _notesController.text = quote.notes ?? '';
    _quoteItems = List.from(quote.items);
    
    // Calculate tax rate from the quote data
    if (quote.subtotal > 0) {
      _taxRate = (quote.taxAmount / quote.subtotal) * 100;
    }
    





  }

  void _findAndSetSelectedClient() {
    if (widget.quote != null) {
      final clientProvider = context.read<ClientProvider>();
      try {
        final client = clientProvider.clients.firstWhere(
          (c) => c.id == widget.quote!.clientId.toString(),
        );
        
        setState(() {
          _selectedClient = client;
        });

      } catch (e) {

        // Client might not be loaded yet, we'll try again when the client dropdown is built
      }
    }
  }

  @override
  void dispose() {
    _quoteNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header with back button and save
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.quote == null ? 'Create Quote' : 'Edit Quote',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: _isLoading ? null : _saveQuote,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildBasicInfoCard(),
                      const SizedBox(height: 16),
                      _buildClientSelectionCard(),
                      const SizedBox(height: 16),
                      _buildItemsCard(),
                      const SizedBox(height: 16),
                      _buildTotalsCard(),
                      const SizedBox(height: 16),
                      _buildNotesCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quoteNumberController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Quote Number',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
              hintText: 'Leave empty to auto-generate',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
            ),
            validator: (value) => null, // Optional field
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, isExpiryDate: false),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quote Date',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_quoteDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, isExpiryDate: true),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expiry Date (Optional)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _expiryDate != null 
                              ? _formatDate(_expiryDate!) 
                              : 'Not set',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Status',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
            ),
            dropdownColor: const Color(0xFF667eea),
            items: const [
              DropdownMenuItem(
                value: 'draft',
                child: Text('Draft', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'sent',
                child: Text('Sent', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'accepted',
                child: Text('Accepted', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'rejected',
                child: Text('Rejected', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'expired',
                child: Text('Expired', style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _status = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<ClientProvider>(
            builder: (context, clientProvider, child) {
              if (clientProvider.isLoading) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (clientProvider.clients.isEmpty) {
                return Text(
                  'No clients available. Please add a client first.',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                );
              }

              // Try to find and set the selected client if we haven't already
              if (widget.quote != null && _selectedClient == null && clientProvider.clients.isNotEmpty) {


                
                try {
                  // Convert both IDs to strings for comparison
                  final targetClientId = widget.quote!.clientId.toString();
                  final client = clientProvider.clients.firstWhere(
                    (c) => c.id == targetClientId,
                  );
                  
                  // Only set if the client is actually in the dropdown items
                  final isClientInList = clientProvider.clients.any((c) => c.id == targetClientId);
                  
                  if (isClientInList) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedClient = client;
                        });

                      }
                    });
                  } else {

                  }
                } catch (e) {

                }
              }

              return DropdownButtonFormField<Client>(
                value: _selectedClient,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Select Client',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                dropdownColor: const Color(0xFF667eea),
                items: clientProvider.clients.map((client) {
                  return DropdownMenuItem(
                    value: client,
                    child: Text(client.name, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (client) {
                  setState(() {
                    _selectedClient = client;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a client';
                  }
                  return null;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quote Items',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: _addQuoteItem,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('Add Item', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_quoteItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No items added yet',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ),
            )
          else
            ..._quoteItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildQuoteItemTile(item, index);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuoteItemTile(QuoteItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                  onPressed: () => _editQuoteItem(index),
                  tooltip: 'Edit item',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                  onPressed: () => _removeQuoteItem(index),
                  tooltip: 'Remove item',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qty: ${item.quantity} × E${item.unitPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                'E${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    final subtotal = _calculateSubtotal();
    final taxAmount = subtotal * (_taxRate / 100);
    final total = subtotal + taxAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Totals',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _taxRate.toString(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tax Rate (%)',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
              suffixText: '%',
              suffixStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _taxRate = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              Text(
                'E${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (${_taxRate.toStringAsFixed(1)}%):',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              Text(
                'E${taxAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'E${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Additional Notes',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
              hintText: 'Enter any additional notes or terms...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isExpiryDate}) async {
    final initialDate = isExpiryDate ? (_expiryDate ?? DateTime.now()) : _quoteDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        if (isExpiryDate) {
          _expiryDate = date;
        } else {
          _quoteDate = date;
        }
      });
    }
  }

  void _addQuoteItem() {
    _showQuoteItemDialog();
  }

  void _editQuoteItem(int index) {
    _showQuoteItemDialog(item: _quoteItems[index], index: index);
  }

  void _removeQuoteItem(int index) {
    setState(() {
      _quoteItems.removeAt(index);
    });
  }

  void _showQuoteItemDialog({QuoteItem? item, int? index}) {
    showDialog(
      context: context,
      builder: (context) => QuoteItemDialog(
        item: item,
        onSave: (newItem) {
          setState(() {
            if (index != null) {
              _quoteItems[index] = newItem;
            } else {
              _quoteItems.add(newItem);
            }
          });
        },
      ),
    );
  }

  double _calculateSubtotal() {
    return _quoteItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate() || _selectedClient == null) {
      return;
    }

    if (_quoteItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final subtotal = _calculateSubtotal();
      final taxAmount = subtotal * (_taxRate / 100);
      final totalAmount = subtotal + taxAmount;

      final quote = Quote(
        id: widget.quote?.id,
        companyId: int.parse(context.read<AuthProvider>().currentUser!['company_id'].toString()),
        clientId: int.parse(_selectedClient!.id),
        quoteNumber: _quoteNumberController.text.trim(),
        quoteDate: _quoteDate,
        expiryDate: _expiryDate,
        status: _status,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: _quoteItems,
      );

      if (widget.quote == null) {
        await context.read<QuoteProvider>().createQuote(quote);
      } else {
        await context.read<QuoteProvider>().updateQuote(quote);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quote == null 
                ? 'Quote created successfully' 
                : 'Quote updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving quote: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class QuoteItemDialog extends StatefulWidget {
  final QuoteItem? item;
  final Function(QuoteItem) onSave;

  const QuoteItemDialog({
    super.key,
    this.item,
    required this.onSave,
  });

  @override
  State<QuoteItemDialog> createState() => _QuoteItemDialogState();
}

class _QuoteItemDialogState extends State<QuoteItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  Item? _selectedItem;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.itemName;
      _descriptionController.text = widget.item!.description;
      _unitPriceController.text = widget.item!.unitPrice.toString();
      _quantityController.text = widget.item!.quantity.toString();
    } else {
      _quantityController.text = '1.0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _unitPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item == null ? 'Add Quote Item' : 'Edit Quote Item',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Consumer<ItemProvider>(
                builder: (context, itemProvider, child) {
                  if (itemProvider.items.isNotEmpty) {
                    return Column(
                      children: [
                        DropdownButtonFormField<Item>(
                          value: _selectedItem,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Select from existing items (optional)',
                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                          ),
                          dropdownColor: const Color(0xFF667eea),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('-- Custom Item --', style: TextStyle(color: Colors.white)),
                            ),
                            ...itemProvider.items.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item.name, style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                          ],
                          onChanged: (item) {
                            setState(() {
                              _selectedItem = item;
                              if (item != null) {
                                _nameController.text = item.name;
                                _descriptionController.text = item.description;
                                _unitPriceController.text = item.price.toString();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitPriceController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Unit Price',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        prefixText: 'E',
                        prefixStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a unit price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a quantity';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: _saveItem,
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final unitPrice = double.parse(_unitPriceController.text);
    final quantity = double.parse(_quantityController.text);
    final totalPrice = unitPrice * quantity;

    final quoteItem = QuoteItem(
      id: widget.item?.id,
      quoteId: widget.item?.quoteId ?? 0,
      itemId: _selectedItem?.id,
      itemName: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      unitPrice: unitPrice,
      quantity: quantity, // Keep as double, don't round
      totalPrice: totalPrice,
    );

    widget.onSave(quoteItem);
    Navigator.pop(context);
  }
}
