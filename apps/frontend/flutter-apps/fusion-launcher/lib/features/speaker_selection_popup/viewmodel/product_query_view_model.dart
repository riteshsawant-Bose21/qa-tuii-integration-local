import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/config/app_config.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/auth_view_model.dart';
import 'package:fusion_launcher/features/authentication/viewmodel/session_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/product_data.dart';
import 'package:fusion_lib/product_data/products.dart';
import 'package:mutex/mutex.dart';

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
  final AppCacheService cacheService;
  ProductQueryViewModel({required this.networkClient, required this.cacheService}) : super(ProductQueryViewModelState.initial()) {
    _productsApi = Products(
      baseUrl: AppConfig.awsApiBaseUrl,
      networkClient: networkClient,
      cacheService: cacheService,
      fusionOnly: true,
      loadFromZip: true,
    );

    loadProducts();
  }

  static const Duration _pricesCacheTtl = Duration(hours: 24);

  final Mutex _pricesMutex = Mutex();

  bool _hasLoadedProducts = false;
  late final AppCacheService pricesCacheService;

  late final Products _productsApi;

  late String localProductDirPath;

  bool get hasCloudAccess => serviceLocator<SessionViewModel>().hasCloudAccess();
  bool get isAuthenticated => serviceLocator<AuthViewModel>().state is Authenticated;

  Future<void> loadProducts({int attempt = 1, bool refresh = false}) async {
    try {
      pricesCacheService = await cacheService.scope('prices');

      if (state.isRefreshing) return;
      if (!refresh && _hasLoadedProducts && state.products != null) return;

      emit(state.copyWith(isLoading: !refresh, isRefreshing: refresh, errorMessage: null));

      await (refresh ? _productsApi.refresh() : _productsApi.initialize());

      _hasLoadedProducts = true;

      emit(state.copyWith(products: _productsApi, isLoading: false, isRefreshing: false));

      if (hasCloudAccess) _fetchAllProductPrices(forceRefresh: refresh);
    } catch (e) {
      emit(state.copyWith(isLoading: false, isRefreshing: false, errorMessage: 'Failed to load products'));
    }
  }

  void _fetchAllProductPrices({bool forceRefresh = false}) async {
    if (hasCloudAccess) {
      for (SpeakerProduct element in speakers) {
        _fetchProductPrices(element.productId, "speakers", forceRefresh: forceRefresh);
      }
      for (AmplifierProduct element in amplifiers) {
        _fetchProductPrices(element.productId, "amplifiers", forceRefresh: forceRefresh);
      }
      for (IoEndpointProduct element in ioEndpoints) {
        _fetchProductPrices(element.productId, "ioEndpoints", forceRefresh: forceRefresh);
      }
      for (DspProduct element in dsps) {
        _fetchProductPrices(element.productId, "dsps", forceRefresh: forceRefresh);
      }
      for (ControllerProduct element in controllers) {
        _fetchProductPrices(element.productId, "controllers", forceRefresh: forceRefresh);
      }
      for (AccessoryProduct element in accessories) {
        _fetchProductPrices(element.productId, "accessories", forceRefresh: forceRefresh);
      }
    }
  }

  void refresh() => loadProducts(refresh: true);

  String? getProductImage(int? productId) => productId != null ? _productsApi.imageFor(productId: productId)?.firstPath : null;

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

  String _priceCacheKey(int productId, String currency) => '${productId}_$currency';

  Future<void> _fetchProductPrices(int productId, String productType, {bool forceRefresh = false}) async {
    final AppCacheService individualProductPriceCacheService = await pricesCacheService.scope(productType);

    // TODO: SHARATH: Currently hardcoding to USD until we have a way to get user's preferred currency.
    // We can add a dropdown in the UI to select currency and pass that value here.
    final String currency = CurrencyType.usd.name.toUpperCase();

    final String cacheKey = _priceCacheKey(productId, currency);

    if (!forceRefresh) {
      final List<ProductPriceModel>? cachedPrices = await individualProductPriceCacheService.getJson<List<ProductPriceModel>>(
        cacheKey,
        (Object? json) {
          final List<dynamic> raw = (json as List<dynamic>? ?? <dynamic>[]);
          return raw.map((dynamic item) => ProductPriceModel.fromJson(item as Map<String, dynamic>)).toList();
        },
      );

      if (cachedPrices != null && cachedPrices.isNotEmpty) {
        await _pricesMutex.protect(() async {
          final Map<int, List<ProductPriceModel>> updatedPrices = Map<int, List<ProductPriceModel>>.from(state.prices);
          updatedPrices[productId] = cachedPrices;
          emit(state.copyWith(prices: updatedPrices));
        });
        return;
      }
    }

    try {
      final ResponseCallback<dynamic> response = await networkClient.get(
        api: FusionApiEndpoint.products,
        additionalPath: "$productId/prices",
        urlParameters: <String, dynamic>{'currency': currency},
      );

      if (response.statusCode == 200) {
        final List<ProductPriceModel> pricesVarientMap = <ProductPriceModel>[];
        for (final dynamic priceJson in (response.data as Map<String, dynamic>)['prices'] ?? <dynamic>[]) {
          final ProductPriceModel price = ProductPriceModel.fromJson(priceJson as Map<String, dynamic>);
          pricesVarientMap.add(price);
        }

        await _pricesMutex.protect(() async {
          final Map<int, List<ProductPriceModel>> updatedPrices = Map<int, List<ProductPriceModel>>.from(state.prices);
          updatedPrices[productId] = pricesVarientMap;
          emit(state.copyWith(prices: updatedPrices));
        });

        await individualProductPriceCacheService.setJson(
          cacheKey,
          pricesVarientMap.map((ProductPriceModel item) => item.toJson()).toList(),
          ttl: _pricesCacheTtl,
        );
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'variant': variant,
      'currency': currency,
      'price': price,
    };
  }

  @override
  List<Object?> get props => <Object?>[variant, currency, price];
}
