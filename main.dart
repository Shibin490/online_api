import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

const String apiUrl ='https://crudcrud.com/api/8d60489b354f4fe99840edd133d7ffa5/products';
const String discountedUrl ='https://crudcrud.com/api/8d60489b354f4fe99840edd133d7ffa5/discountedProducts';

class Product {
  String id;
  String name;
  double price;
  int quantity;

  Product(this.id, this.name, this.price, this.quantity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      json['id'].toString(),
      json['name'],
      json['price'].toDouble(),
      json['quantity'],
    );
  }

  void printDetails() {
    print('ID: $id, Product: $name, Price: \$$price, Quantity: $quantity');
  }

  double getFinalPrice() => price;
}

class DiscountedProduct extends Product {
  double discount;

  DiscountedProduct(
      String id, String name, double price, int quantity, this.discount)
      : super(id, name, price, quantity);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'discount': discount,
      };

  factory DiscountedProduct.fromJson(Map<String, dynamic> json) {
    return DiscountedProduct(
      json['id'].toString(),
      json['name'],
      json['price'].toDouble(),
      json['quantity'],
      json['discount'].toDouble(),
    );
  }

  @override
  void printDetails() {
    print(
        'ID: $id, Product: $name, Price: \$$price, Quantity: $quantity, Discount: $discount%');
  }

  @override
  double getFinalPrice() {
    return price - (price * (discount / 100));
  }
}

class ShoppingCart {
  List<Product> products = [];
  List<DiscountedProduct> discountedProducts = [];

  Future<void> addProduct(Product product) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      print('Product added successfully.');
    } else {
      print('Failed to add product. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  Future<void> addDiscountedProduct(DiscountedProduct product) async {
    final response = await http.post(
      Uri.parse(discountedUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      print('Discounted product added successfully.');
    } else {
      print('Failed to add discounted product. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

 Future<void> updateProduct(Product product) async {
  String endpointUrl = '$apiUrl/${product.id}';

  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> productList = jsonDecode(response.body);

      var existingProduct = productList.firstWhere(
        (prod) => prod['id'] == product.id,
        orElse: () => null,
      );

      if (existingProduct != null) {
        print('Product with ID ${product.id} found.');

        while (true) {
          print('\nSelect the detail you want to update:');
          print('1. Name');
          print('2. Price');
          print('3. Quantity');
          print('4. Exit');

          String? choice = stdin.readLineSync();

          switch (choice) {
            case '1':
              print('Enter updated product name:');
              product.name = stdin.readLineSync()!;
              break;
            case '2':
              print('Enter updated product price:');
              product.price = double.parse(stdin.readLineSync()!);
              break;
            case '3':
              print('Enter updated product quantity:');
              product.quantity = int.parse(stdin.readLineSync()!);
              break;
            case '4':
              print('Exiting update process...');
              return;
            default:
              print('Invalid choice. Please try again.');
              continue;
          }


          print('Updated details:');
          print('ID: ${product.id}, Product: ${product.name}, Price: \$${product.price}, Quantity: ${product.quantity}');
          print('Do you want to save these changes? (y/n)');

          String? saveChoice = stdin.readLineSync();
          if (saveChoice?.toLowerCase() == 'y') {
            final updateResponse = await http.put(
              Uri.parse(endpointUrl),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(product.toJson()),
            );


            if (updateResponse.statusCode == 200) {
              print('Product updated successfully.');
              return; 
            } else {
              print('Failed to update product. Status code: ${updateResponse.statusCode}');
            }
          } else {
            print('Changes not saved.');
            return;}
        }
      } else {
        print('Product with ID ${product.id} not found.');
      }
    } else {
      print('Failed to fetch products. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error updating product: $e');
  }
}


  Future<void> updateDiscountedProduct(DiscountedProduct product) async {
    String endpointUrl = '$discountedUrl/${product.id}';

    try {
      final response = await http.get(Uri.parse(discountedUrl));
      if (response.statusCode == 200) {
        List<dynamic> discountedProductList = jsonDecode(response.body);

        var existingDiscountedProduct = discountedProductList
            .firstWhere((prod) => prod['id'] == product.id, orElse: () => null);

        if (existingDiscountedProduct != null) {
          final updateResponse = await http.put(
            Uri.parse(endpointUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(product.toJson()),
          );

          if (updateResponse.statusCode == 200) {
            print('Discounted product updated successfully.');
          } else {
            print('Failed to update discounted product. Status code: ${updateResponse.statusCode}');
          }
        } else {
          print('Discounted product with ID ${product.id} not found.');
        }
      } else {
        print('Failed to fetch discounted products. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating discounted product: $e');
    }
  }

  Future<void> removeProduct(String id) async {
    print('Attempting to remove product with ID: $id');

    final response = await http.get(Uri.parse('$apiUrl'));
    final discountedResponse = await http.get(Uri.parse('$discountedUrl'));

    if (response.statusCode == 200) {
      List<dynamic> productList = jsonDecode(response.body);

      for (var productJson in productList) {
        String serverId = productJson['_id'];

        if (productJson['id'] == id) {
          final deleteResponse =
              await http.delete(Uri.parse('$apiUrl/$serverId'));

          if (deleteResponse.statusCode == 200) {
            print('Product removed successfully.');
            products.removeWhere((product) => product.id == id);
          } else {
            print('Failed to remove product.');
          }
          break;
        }
      }
    } else {
      print('Failed to fetch products. Status code: ${response.statusCode}');
    }

    if (discountedResponse.statusCode == 200) {
      List<dynamic> discountedProductList = jsonDecode(discountedResponse.body);

      for (var discountedProductJson in discountedProductList) {
        String serverId =
            discountedProductJson['_id'];

        if (discountedProductJson['id'] == id) {
          final deleteResponse =
              await http.delete(Uri.parse('$discountedUrl/$serverId'));

          if (deleteResponse.statusCode == 200) {
            print('Discounted product removed successfully.');
            discountedProducts.removeWhere((product) => product.id == id);
          } else {
            print('Failed to remove discounted product.');
          }
          break;
        }
      }
    } else {
      print('Failed to fetch discounted products. Status code: ${response.statusCode}');
    }
  }

  Future<void> viewCart() async {
    try {
      products.clear();
      discountedProducts.clear();

      final response = await http.get(Uri.parse(apiUrl));
      final discountedResponse = await http.get(Uri.parse(discountedUrl));

      if (response.statusCode == 200) {
        List<dynamic> productList = jsonDecode(response.body);
        products = productList.map((e) => Product.fromJson(e)).toList();
      } else {
        print('Failed to load products. Status code: ${response.statusCode}');
      }

      if (discountedResponse.statusCode == 200) {
        List<dynamic> discountedProductList = jsonDecode(discountedResponse.body);
        discountedProducts = discountedProductList
            .map((e) => DiscountedProduct.fromJson(e))
            .toList();
      } else {
        print('Failed to load discounted products. Status code: ${discountedResponse.statusCode}');
      }

      print('Current Cart:');
      products.forEach((product) => product.printDetails());
      discountedProducts.forEach((discountedProduct) => discountedProduct.printDetails());

      double total = 0;

      products.forEach((product) {
        total += product.getFinalPrice();
      });

      discountedProducts.forEach((discountedProduct) {
        total += discountedProduct.getFinalPrice();
      });

      print('Total price: \$${total}');
    } catch (e) {
      print('Error viewing cart: $e');
    }
  }
}


void main() async {
  ShoppingCart cart = ShoppingCart();

  while (true) {
    print('\nShopping Cart Menu:');
    print('1. Add Product');
    print('2. Add Discounted Product');
    print('3. View Cart');
    print('4. Remove Product');
    print('5. Update Product');
    print('6. Update Discounted Product');
    print('7. Exit');
    String? choice = stdin.readLineSync();
    print("enter your choise");
    switch (choice) {
   case '1':
  print('Enter product details:');


  String id = '';
  bool validId = false;
  while (!validId) {
    print('Enter ID (positive number):');
    id = stdin.readLineSync()!;
    if (id.isEmpty || int.tryParse(id) == null || int.parse(id) <= 0) {
      print('Invalid ID. Please enter a positive number.');
    } else {
      validId = true;
    }
  }

  String name = '';
  bool validName = false;
  while (!validName) {
    print('Enter name (must start with a letter and cannot be empty):');
    name = stdin.readLineSync()!;
    if (name.isEmpty || !RegExp(r'^[a-zA-Z]').hasMatch(name)) {
      print('Invalid name. It must start with a letter and cannot be empty.');
    } else {
      validName = true;
    }
  }

  double price = -1;
  bool validPrice = false;
  while (!validPrice) {
    print('Enter price (positive number):');
    String priceInput = stdin.readLineSync()!;
    if (priceInput.isEmpty || double.tryParse(priceInput) == null || double.parse(priceInput) <= 0) {
      print('Invalid price. Please enter a positive number.');
    } else {
      price = double.parse(priceInput);
      validPrice = true;
    }
  }

  int quantity = -1;
  bool validQuantity = false;
  while (!validQuantity) {
    print('Enter quantity (positive number):');
    String quantityInput = stdin.readLineSync()!;
    if (quantityInput.isEmpty || int.tryParse(quantityInput) == null || int.parse(quantityInput) <= 0) {
      print('Invalid quantity. Please enter a positive number.');
    } else {
      quantity = int.parse(quantityInput);
      validQuantity = true;
    }
  }


  Product newProduct = Product(id, name, price, quantity);
  await cart.addProduct(newProduct);
  break;

case '2':
  print('Enter discounted product details:');


  String discountedId = '';
  bool validDiscountedId = false;
  while (!validDiscountedId) {
    print('Enter ID (positive number):');
    discountedId = stdin.readLineSync()!;
    if (discountedId.isEmpty || int.tryParse(discountedId) == null || int.parse(discountedId) <= 0) {
      print('Invalid ID. Please enter a positive number.');
    } else {
      validDiscountedId = true;
    }
  }

  String discountedName = '';
  bool validDiscountedName = false;
  while (!validDiscountedName) {
    print('Enter name (must start with a letter and cannot be empty):');
    discountedName = stdin.readLineSync()!;
    if (discountedName.isEmpty || !RegExp(r'^[a-zA-Z]').hasMatch(discountedName)) {
      print('Invalid name. It must start with a letter and cannot be empty.');
    } else {
      validDiscountedName = true;
    }
  }

  double discountedPrice = -1;
  bool validDiscountedPrice = false;
  while (!validDiscountedPrice) {
    print('Enter price (positive number):');
    String discountedPriceInput = stdin.readLineSync()!;
    if (discountedPriceInput.isEmpty || double.tryParse(discountedPriceInput) == null || double.parse(discountedPriceInput) <= 0) {
      print('Invalid price. Please enter a positive number.');
    } else {
      discountedPrice = double.parse(discountedPriceInput);
      validDiscountedPrice = true;
    }
  }

  int discountedQuantity = -1;
  bool validDiscountedQuantity = false;
  while (!validDiscountedQuantity) {
    print('Enter quantity (positive number):');
    String discountedQuantityInput = stdin.readLineSync()!;
    if (discountedQuantityInput.isEmpty || int.tryParse(discountedQuantityInput) == null || int.parse(discountedQuantityInput) <= 0) {
      print('Invalid quantity. Please enter a positive number.');
    } else {
      discountedQuantity = int.parse(discountedQuantityInput);
      validDiscountedQuantity = true;
    }
  }

  double discount = -1;
  bool validDiscount = false;
  while (!validDiscount) {
    print('Enter discount percentage (0 to 100):');
    String discountInput = stdin.readLineSync()!;
    if (discountInput.isEmpty || double.tryParse(discountInput) == null || double.parse(discountInput) <= 0 || double.parse(discountInput) > 100) {
      print('Invalid discount. Please enter a percentage between 0 and 100.');
    } else {
      discount = double.parse(discountInput);
      validDiscount = true;
    }
  }
  DiscountedProduct newDiscountedProduct =
      DiscountedProduct(discountedId, discountedName, discountedPrice, discountedQuantity, discount);
  await cart.addDiscountedProduct(newDiscountedProduct);
  break;

      case '3':
        await cart.viewCart();
        break;

      case '4':
        print('Enter the ID of the product to remove:');
        String removeId = stdin.readLineSync()!;
        await cart.removeProduct(removeId);
        break;

      case '5':
        print('Enter the ID of the product to update:');
        String updateId = stdin.readLineSync()!;
        Product updatedProduct = Product(updateId, '', 0.0, 0);
        await cart.updateProduct(updatedProduct);
        break;

      case '6':
        print('Enter the ID of the discounted product to update:');
        String discountedUpdateId = stdin.readLineSync()!;
        DiscountedProduct updatedDiscountedProduct =
            DiscountedProduct(discountedUpdateId, '', 0.0, 0, 0);
        await cart.updateDiscountedProduct(updatedDiscountedProduct);
        break;
      case '7':
        print('Goodbye!');
        return;

      default:
        print('Invalid option. Please try again.');
    }
  }
}
