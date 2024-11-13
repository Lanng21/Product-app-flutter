import 'dart:math';
import 'package:doandidongappthuongmai/models/load_data.dart';
import 'package:doandidongappthuongmai/view/OrderDetailScreen.dart';
import 'package:doandidongappthuongmai/view/ProductDetailScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doandidongappthuongmai/models/local_notification.dart';

class PaymentScreen extends StatefulWidget {
  final String Id;
  final List<Cart> selectedProducts;

  const PaymentScreen(
      {Key? key, required this.selectedProducts, required this.Id})
      : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

int stringToInt(String Value) {
  // chuyển kiểu chuổi về kiểu int
  String cleanedString =
      Value.replaceAll('.', ''); //xóa các dấu . , trong chuỗi
  return int.parse(cleanedString);
}

String intToString(int number) {
  // chuyển kiểu int về lại chuổi theo định dạng tiền việt nam
  NumberFormat format = NumberFormat('#,###', 'vi_VN');
  return format.format(number);
}

String getNextday(int numberdays) {
  //lấy ngày tíêp theo
  DateTime now = DateTime.now(); //lấy ngày ht
  DateTime nextday = now
      .add(Duration(days: numberdays)); //  ht + số ngày nhập --> ngày típ theo
  String formatNextday =
      DateFormat('dd-MM').format(nextday); // định dạng ngày và tháng
  return formatNextday;
}

String totalPayment(int productprice, String phigiaohang) {
  // tính tiền tổng hóa đơn
  int total = (productprice) + stringToInt(phigiaohang);
  return intToString(total);
}

String ProductMoney(int price, int Quantity) // tính tiền sản phẩm
{
  int money = (price * Quantity);
  return intToString(money);
}

// tạo thông tin mặc định
String typePayment = "Tiền mặt khi nhận hàng";
const String phigiaohang = "15.000";
const String status = "Đang xử lý";

class _PaymentScreenState extends State<PaymentScreen> {
  late String orderId;

  Users users = Users(
    name: "",
    email: "",
    phone: "",
    typeaccount: false,
    status: true,
    address: "",
    image: "",
  );
  String productMoney = "0"; // Tổng tiền hàng
  String Payment = "0"; // Tổng đơn (tổng tiền hàng + phí giao hàng)

  @override
  void initState() {
    super.initState();
    loadOrderId();
    loadCurrentUser(widget.Id);
  }

  void loadCurrentUser(String userId) async {
    try {
      Users user = await Users.fetchUser(userId);
      setState(() {
        users = user;
      });
    } catch (error) {
      print("Error loading user data: $error");
    }
  }

  void loadOrderId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      orderId = prefs.getString('orderId') ?? RandomIdOrder();
    });
  }

  void saveOrderId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('orderId', orderId);
  }

  int selectedPaymentOption = 1;
  @override
  Widget build(BuildContext context) {
    int calculateProductMoney() {
      int total = 0;
      for (var product in widget.selectedProducts) {
        int discountedPrice =
            getPromotionOrPrice(product.price, product.promotion);
        total += discountedPrice * product.quantity;
      }
      return total;
    }

    // Cập nhật giá trị tổng tiền hàng khi màn hình được build
    productMoney = intToString(calculateProductMoney());

    // Cập nhật giá trị tổng đơn (tổng tiền hàng + phí giao hàng)
    Payment = totalPayment(stringToInt(productMoney), phigiaohang);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        title: const Text(
          "Thanh toán",
          style: TextStyle(color: Colors.black, fontSize: 25),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 15, 0, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30,
                  ),
                  Text(
                    "Địa chỉ nhận hàng",
                    style: TextStyle(fontSize: 20),
                  )
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  height: 140,
                  padding: EdgeInsets.fromLTRB(35, 5, 0, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 1.2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Text(users.name, style: TextStyle(fontSize: 17)),
                        ],
                      ),
                      SizedBox(
                        height: 13,
                      ),
                      Row(
                        children: [
                          Text(
                            users.phone,
                            style: TextStyle(fontSize: 17),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 13,
                      ),
                      Expanded(
                        child: Text(
                          users.address,
                          style: TextStyle(fontSize: 17),
                          softWrap: true,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Column(
              children: widget.selectedProducts.map((product) {
                return Container(
                  height: 130,
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(
                      bottom: 10), // Để tạo khoảng cách giữa các sản phẩm
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.2),
                        ),
                        margin: EdgeInsets.only(right: 15),
                        child: Image.network(
                          product.image,
                          width: 100,
                          height: 110,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              product.productName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Số lượng: ',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      product.quantity.toString(),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    (product.promotion == 0)
                                        ? Text('đ${intToString(product.price)}',
                                            style: TextStyle(fontSize: 16))
                                        : Text(
                                            'đ${intToString(product.promotion)}',
                                            style: TextStyle(fontSize: 16)),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(
              height: 1,
            ),
            Column(
              children: [
                Container(
                  height: 120,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hình thức vận chuyển",
                            style: TextStyle(fontSize: 20),
                          ),
                          Text("Nhanh", style: TextStyle(fontSize: 18)),
                          Text(
                            "Nhận hàng vào ${getNextday(2)} - ${getNextday(5)}",
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic),
                          )
                        ],
                      )),
                      Container(
                        width: MediaQuery.sizeOf(context).width / 5 - 15,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "đ${phigiaohang}",
                              style:
                                  TextStyle(fontSize: 17, color: Colors.black),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chọn hình thức thanh toán",
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      RadioButton(1, Icons.money, "Tiền mặt khi nhận hàng"),
                      RadioButton(2, Icons.wallet, "Ví Momo"),
                      RadioButton(3, Icons.home_work_outlined, "Chuyển khoản"),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              height: 1,
            ),
            Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 160,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "THÔNG TIN HÓA ĐƠN",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Tiền hàng", style: TextStyle(fontSize: 20)),
                          Text(
                            productMoney + 'đ',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Phí giao hàng",
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            phigiaohang + 'đ',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tổng đơn hàng",
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            Payment + 'đ',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await initNotifications();
                      OrderDetails orderDetailsInfo = OrderDetails(
                        OrderId: orderId,
                        products: widget
                            .selectedProducts, // Thêm danh sách sản phẩm vào đơn hàng
                        name: users.name,
                        phone: users.phone,
                        address: users.address,
                        typePayment: typePayment,
                        productmoney: productMoney,
                        deliverycharges: phigiaohang,
                        totalPayment: Payment,
                        status: status,
                      );
                      showOrderSuccessNotification();

                      saveOrderToFirebase(orderDetailsInfo, orderId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(
                                  orderdetailinfo: orderDetailsInfo,
                                  Id: widget.Id,
                                )),
                      );
                    }, //chuyển đến chi tiết hóa đơn

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[300],
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Đặt hàng ngay",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget RadioButton(int value, IconData icon, String text) {
    // Tạo đối tượng Radio Button và xử lý sự kiện khi người dùng chọn
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentOption = value; //lấy giá trị khi có radio đó dc chọn
          typePayment = text;
        });
      },
      child: Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(
              color: selectedPaymentOption == value
                  ? Color.fromARGB(255, 145, 218, 128)
                  : Colors.grey,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedPaymentOption == value
                      ? Color.fromARGB(255, 145, 218, 128)
                      : Colors.transparent,
                  border: Border.all(
                    color: selectedPaymentOption == value
                        ? Color.fromARGB(255, 145, 218, 128)
                        : Colors.grey,
                    width: 1.0,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Icon(
                icon,
                size: 30,
                color:
                    selectedPaymentOption == value ? Colors.green : Colors.grey,
              ),
              SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  color: selectedPaymentOption == value
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
            ],
          )),
    );
  }
}

String RandomIdOrder() {
  //tạo mã đơn hàng ngẫu nhiên có 10 ký tự
  const String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final Random random = Random();
  final int length = 10;

  String Id = '';
  for (int i = 0; i < length; i++) {
    final int randomIndex =
        random.nextInt(characters.length); //trả về một ký tự  ngẫu nhiên
    Id += characters[randomIndex];
  }
  return Id;
}

void saveOrderToFirebase(OrderDetails orderDetails, String orderId) {
  DatabaseReference ordersRef = FirebaseDatabase.instance.ref().child('orders');
  var newOrderRef = ordersRef.child(orderId);
  List<Map<String, dynamic>> productsList = [];
  for (var product in orderDetails.products) {
    Map<String, dynamic> productData;

    if (product.promotion != null && product.promotion > 0) {
      productData = {
        'image': product.image,
        'productName': product.productName,
        'price': product.promotion,
        'quantity': product.quantity,
        'idproduct': product.idproduct
      };
    } else {
      productData = {
        'image': product.image,
        'productName': product.productName,
        'price': product.price,
        'quantity': product.quantity,
        'idproduct': product.idproduct
      };
    }
    productsList.add(productData);
  }
  newOrderRef.set({
    'OrderId': orderId,
    'name': orderDetails.name,
    'phone': orderDetails.phone,
    'address': orderDetails.address,
    'productmoney': orderDetails.productmoney,
    'status': orderDetails.status,
    'products': productsList,
  });
}
