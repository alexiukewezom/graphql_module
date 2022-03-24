# GraphQL Module

Модуль GraphQL клиента работающий на библиотеке [graphql](https://pub.dev/packages/graphql).
## Инициализация 

Для DI используется GetX.

```dart
await Get.putAsync(
  () => GraphModule(
    baseUrl: '{ url }',
    getHeaders: () async => {
      'Authorization': 'Bearer ${SPCache.getAccessToken()}',
    },
    refreshEngine: GraphModuleRefreshEngine(
      getRefreshToken: () async => SPCache.getRefreshToken(),
      sendRefresh: () async => await AuthRepository.refreshToken(),
    ),
    onTokenRot: () {
      AppBuilder.bloc.logout();
    },
    handleError: (exception) {
     
    },
  ).init(),
);
```

## Usage
### Create Repository
```dart
class FaqRepository {
  // AppResponse имеет generic возвращаемого типа (рекомендуется всегда делать опциональным тк запрос может вернуть ошибку)
  static Future<AppResponse<List<FAQGroupModel>?>> faqGroups() async {
    print('FaqRepository: faqGroups...');
    final QueryOptions options = QueryOptions(
      // Документ содержит в себе запрос созданный в плейграунде (реализация следующий шаг)
      document: gql(FaqPlayground.faqGroups),
    );

    // Выполнение запроса
    final result = await GraphModule.module.request(options);
    if (result.success) {
      // Парсинг успешного ответа
      try {
        return AppResponse<List<FAQGroupModel>>(
          success: true,
          data: List<FAQGroupModel>.from(
            (result.data['faqGroups'] ?? []).map(
              (x) => FAQGroupModel.fromNetwork(x),
            ),
          ),
        );
      } catch (err) {
        print(err);
      }
    }
    // Преобразование ответа от GraphModule в нужный generic с сохранением ошибок и возвратом success: false
    return result.newGeneric<List<FAQGroupModel>?>(success: false);
  }
}
```
### Create Playground
```dart
class FaqPlayground {
  static String faqGroups =
      'query faqGroups { faqGroups { ${FAQGroupModel.graph} } }';
}

class FAQGroupModel {
  final String id;
  final String name;

  // Перечень запрашиваемых объектов  
  static String graph = 'id name';
  static String graphShort = 'id';
}
```
