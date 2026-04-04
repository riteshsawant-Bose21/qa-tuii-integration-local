import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/config/app_config.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/session_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/product_data.dart';
import 'package:fusion_lib/product_data/products.dart';

import '../../../core/service_locator.dart';

/// ViewModel to query product data from the Products API
/// This ViewModel called from the ProjectWorkArea widget
/// and is used to query the products data from the Products API

class ProductQueryViewModelState extends Equatable {
  final Products? products;
  final Map<int, List<ProductPriceModel>> prices; // productId: list of prices
  final bool isLoading;
  final bool isRefreshing;
  final String errorMessage;

  const ProductQueryViewModelState({
    this.products,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage = '',
    this.prices = const <int, List<ProductPriceModel>>{},
  });

  factory ProductQueryViewModelState.initial() => const ProductQueryViewModelState(isLoading: true);

  // copywith
  ProductQueryViewModelState copyWith({
    Products? products,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    Map<int, List<ProductPriceModel>>? prices,
  }) {
    return ProductQueryViewModelState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage ?? this.errorMessage,
      prices: prices ?? this.prices,
    );
  }

  @override
  List<Object?> get props => <Object?>[products, isLoading, isRefreshing, errorMessage, prices];
}

class ProductQueryViewModel extends Cubit<ProductQueryViewModelState> {
  final FusionNetworkClient networkClient;
  ProductQueryViewModel({required this.networkClient}) : super(ProductQueryViewModelState.initial()) {
    loadProducts();
  }

  static const int _maxRetries = 1;

  Products get _productsApi => Products(
    baseUrl: AppConfig.awsApiBaseUrl,
    networkClient: networkClient,
    fusionOnly: true,
  );

  late String localProductDirPath;

  bool get hasCloudAccess => serviceLocator<SessionViewModel>().hasCloudAccess();

  Future<void> loadProducts({int attempt = 1, bool refresh = false}) async {
    try {
      if (state.isRefreshing) return;

      if (refresh) emit(state.copyWith(isRefreshing: true));
      await (refresh ? _productsApi.refresh() : _productsApi.initialize());
      emit(state.copyWith(products: _productsApi, isLoading: false, isRefreshing: false));

      if (hasCloudAccess) {
        for (SpeakerProduct element in speakers) {
          _fetchProductPrices(element.id);
        }
        for (AmplifierProduct element in amplifiers) {
          _fetchProductPrices(element.id);
        }
        for (IoEndpointProduct element in ioEndpoints) {
          _fetchProductPrices(element.id);
        }
        for (DspProduct element in dsps) {
          _fetchProductPrices(element.id);
        }
        for (ControllerProduct element in controllers) {
          _fetchProductPrices(element.id);
        }
        for (AccessoryProduct element in accessories) {
          _fetchProductPrices(element.id);
        }
      }
    } catch (e) {
      if (attempt < _maxRetries) {
        // optional small delay before retry
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return loadProducts(attempt: attempt + 1);
      }

      // failed after 3 attempts
      emit(state.copyWith(products: null, isLoading: false, errorMessage: 'Failed to load products'));
    }
  }

  void refresh() => loadProducts(refresh: true);

  // ---------- get image ----------
  String getImagePath(String imageUrl) => _productsApi.getImagePath(imageUrl);

  // ---------- get image name ----------
  String getImageName(String imageUrl) => _productsApi.getImageName(imageUrl);

  bool get isLoading => state.isLoading;
  String get errorMessage => state.errorMessage;

  // ---------- Convenience getters ----------
  List<SpeakerProduct> get speakers => state.products?.speakers ?? const <SpeakerProduct>[];
  List<AmplifierProduct> get amplifiers => state.products?.amplifiers ?? const <AmplifierProduct>[];
  List<IoEndpointProduct> get ioEndpoints => state.products?.ioEndpoints ?? const <IoEndpointProduct>[];
  List<DspProduct> get dsps => state.products?.dsps ?? const <DspProduct>[];
  List<ControllerProduct> get controllers => state.products?.controllers ?? const <ControllerProduct>[];
  List<AccessoryProduct> get accessories => state.products?.accessories ?? const <AccessoryProduct>[];

  double getPrice(int productId) {
    final List<ProductPriceModel> prices = state.prices[productId] ?? const <ProductPriceModel>[];
    return prices.isNotEmpty ? prices.first.price : 0.0;
  }

  // get prices call api
  Future<void> _fetchProductPrices(int productId) async {
    try {
      final Dio dio = Dio();
      final Response<dynamic> response = await dio.get(
        '${AppConfig.awsApiBaseUrl}/products/$productId/prices',
        queryParameters: <String, dynamic>{'currency': CurrencyType.usd.name.toUpperCase()},
      );
      if (response.statusCode == 200) {
        final List<ProductPriceModel> pricesVarientMap = <ProductPriceModel>[];

        for (final dynamic priceJson in response.data["prices"] ?? <dynamic>[]) {
          final ProductPriceModel price = ProductPriceModel.fromJson(priceJson as Map<String, dynamic>);
          pricesVarientMap.add(price);
        }

        final Map<int, List<ProductPriceModel>> updatedPrices = Map<int, List<ProductPriceModel>>.from(state.prices);
        updatedPrices[productId] = pricesVarientMap;
        emit(state.copyWith(prices: updatedPrices));
      }
    } catch (e) {
      //
    }
  }
}

class ProductPriceModel extends Equatable {
  final String variant;
  final String currency;
  final double price;

  const ProductPriceModel({required this.variant, required this.currency, required this.price});

  factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
    return ProductPriceModel(
      variant: json['variant'] as String,
      currency: json['currency'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => <Object?>[variant, currency, price];
}
