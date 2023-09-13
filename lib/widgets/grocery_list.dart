import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:udemy_http/data/categories.dart';
import 'package:udemy_http/models/category.dart';

import 'package:udemy_http/models/grocery_item.dart';
import 'package:udemy_http/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

/*   void _loadItems() async {
    final uri = Uri.https('flutter-prep-test-cc268-default-rtdb.firebaseio.com',
        'shopping-list.json');
    final response = await http.get(uri);

    if (response.statusCode >= 400) {
      setState(() {
        error = 'error fetching data,please try again later';
      });
    }

    Map<String, dynamic> listData = json.decode(response.body);
    List<GroceryItem> loadedItems = [];
    for (var item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
  } */

  Future<List<GroceryItem>> _loadItems() async {
    final uri = Uri.https('flutter-prep-test-cc268-default-rtdb.firebaseio.com',
        'shopping-list.json');

    final response = await http.get(uri);

    if (response.statusCode >= 400) {
      // setState(() {
      //   _error = 'failed to getch data,please try again later';
      // });
      throw Exception('failed to getch data,please try again later');
    }

    if (response.body == 'null') {
      return [];
    }

    Map<String, dynamic> listData = json.decode(response.body);
    List<GroceryItem> loadedItems = [];
    for (var item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category),
      );
    }

    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) {
    final uri = Uri.https('flutter-prep-test-cc268-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    http.delete(uri);

    setState(() {
      _groceryItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      // body: content,
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No items added yet.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              onDismissed: (direction) {
                _removeItem(snapshot.data![index]);
              },
              key: ValueKey(snapshot.data![index].id),
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(
                  snapshot.data![index].quantity.toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
