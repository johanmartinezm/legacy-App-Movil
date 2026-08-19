import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/graphql_post_model.dart';
import '../../domain/models/book_model.dart';
import '../../domain/models/program_model.dart';
import '../config/config_service.dart';

class GraphqlService {
  final String _baseUrl = ConfigService.graphqlBaseUrl;

  Future<List<GraphqlProgram>> getPrograms({int first = 20}) async {
    const String query = r'''
      query GetPrograms($first: Int) {
        products(first: $first, where: {category: "programas"}) {
          nodes {
            id
            name
            description
            shortDescription
            image {
              sourceUrl
            }
            ... on SimpleProduct {
              price
              regularPrice
            }
            productCategories {
              nodes {
                name
                slug
              }
            }
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {'first': first},
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['errors'] != null) {
          print('GraphQL Errors: ${data['errors']}');
          throw Exception('GraphQL Error: ${data['errors'][0]['message']}');
        }

        final List<dynamic> programsJson = data['data']['products']['nodes'];
        return programsJson.map((json) => GraphqlProgram.fromJson(json)).toList();
      } else {
        print('HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load programs: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in getPrograms: $e');
      rethrow;
    }
  }

  Future<List<GraphqlBook>> getBooks({int first = 10}) async {
    const String query = r'''
      query GetBooks($first: Int) {
        products(first: $first, where: {category: "libros"}) {
          nodes {
            id
            name
            description
            shortDescription
            image {
              sourceUrl
              altText
            }
            ... on SimpleProduct {
              price
              regularPrice
              stockStatus
            }
            ... on VariableProduct {
              price
              regularPrice
            }
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {'first': first},
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> booksJson = data['data']['products']['nodes'];
        return booksJson.map((json) => GraphqlBook.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching books: $e');
      return [];
    }
  }

  Future<GraphqlPostsResponse> getPosts({
    int first = 10,
    String? after,
    String? categoryName,
    String? search,
  }) async {
    const String query = r'''
      query GetPosts($first: Int, $after: String, $categoryName: String, $search: String) {
        posts(first: $first, after: $after, where: {categoryName: $categoryName, search: $search}) {
          pageInfo {
            hasNextPage
            endCursor
          }
          nodes {
            id
            title
            date
            excerpt
            content
            featuredImage {
              node {
                sourceUrl
              }
            }
            author {
              node {
                name
              }
            }
            categories {
              nodes {
                name
                slug
              }
            }
          }
        }
      }
    ''';

    try {
      print(
        'GraphQL Query Variables: ${jsonEncode({'first': first, 'after': after, 'categoryName': categoryName})}',
      );
      final response = await http.post(
        Uri.parse(ConfigService.contentGraphqlUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {
            'first': first,
            'after': after,
            'categoryName': categoryName,
            'search': search,
          },
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic> postsData = data['data']['posts'];
        final List<dynamic> nodes = postsData['nodes'];
        final Map<String, dynamic> pageInfo = postsData['pageInfo'];

        return GraphqlPostsResponse(
          posts: nodes.map((json) => GraphqlPost.fromJson(json)).toList(),
          endCursor: pageInfo['endCursor'],
          hasNextPage: pageInfo['hasNextPage'],
        );
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      return GraphqlPostsResponse(posts: [], hasNextPage: false);
    }
  }

  Future<GraphqlPost?> getPostBySlug(String slug) async {

    const String query = r'''
      query GetPostBySlug($id: ID!) {
        post(id: $id, idType: SLUG) {
          id
          title
          date
          excerpt
          content
          featuredImage {
            node {
              sourceUrl
            }
          }
          author {
            node {
              name
            }
          }
          categories {
            nodes {
              name
              slug
            }
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(ConfigService.contentGraphqlUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {'id': slug},
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['data']['post'] == null) return null;
        return GraphqlPost.fromJson(data['data']['post']);
      }
      return null;
    } catch (e) {
      print('Error fetching post by slug: $e');
      return null;
    }
  }
}
