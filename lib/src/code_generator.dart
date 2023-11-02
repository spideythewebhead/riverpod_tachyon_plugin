import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto show sha1;
import 'package:tachyon/tachyon.dart';

class RiverpodCodeGenerator extends TachyonPluginCodeGenerator {
  @override
  FutureOr<String> generate(
    FileChangeBuildInfo buildInfo,
    TachyonDeclarationFinder declarationFinder,
    Logger logger,
  ) async {
    final CodeWriter codeWriter = CodeWriter.stringBuffer();

    for (final FunctionDeclaration functionDeclaration
        in buildInfo.compilationUnit.functionDeclarations) {
      final AnnotationValueExtractor riverpodAnnotation =
          AnnotationValueExtractor(
              functionDeclaration.metadata.firstWhereOrNull(
        (Annotation annotation) =>
            annotation.name.name.toLowerCase() == 'riverpod',
      ));

      if (!riverpodAnnotation.isValidAnnotation) {
        continue;
      }

      final (String dependencies, String allTransitiveDependencies) =
          _getDependenciesAndAllTransitiveDependencies(
              riverpodAnnotation: riverpodAnnotation);

      final String functionName = functionDeclaration.name.lexeme;
      final String hashFunctionName = '_\$${functionName}Hash';

      codeWriter
        ..writeln(
            "String $hashFunctionName() => r'${functionDeclaration.sha1}';")
        ..writeln();

      if ((functionDeclaration
                  .functionExpression.parameters?.parameters.length ??
              1) >
          1) {
        _writeFamilyProviderForFunction(
          codeWriter: codeWriter,
          functionDeclaration: functionDeclaration,
          riverpodAnnotation: riverpodAnnotation,
          hashFunctionName: hashFunctionName,
          dependencies: dependencies,
          allTransitiveDependencies: allTransitiveDependencies,
        );
        continue;
      }

      final TachyonDartType returnType =
          functionDeclaration.returnType.customDartType;
      final String providerName = '${functionName}Provider';

      final bool isKeepAliveProvider =
          riverpodAnnotation.getBool('keepAlive') ?? false;
      final String notifierPrefix = isKeepAliveProvider ? '' : 'AutoDispose';

      final String riverpodProviderName;
      final String riverpodProviderTypeParams;
      if (returnType.name == 'Future' || returnType.name == 'FutureOr') {
        riverpodProviderName = '${notifierPrefix}FutureProvider';
        riverpodProviderTypeParams = returnType.typeArguments
            .map((TachyonDartType typeParam) => typeParam.fullTypeName)
            .join(', ');
      } else if (returnType.name == 'Stream') {
        riverpodProviderName =
            riverpodProviderName = '${notifierPrefix}StreamProvider';
        riverpodProviderTypeParams = returnType.typeArguments
            .map((TachyonDartType typeParam) => typeParam.fullTypeName)
            .join(', ');
      } else {
        riverpodProviderName = '${notifierPrefix}Provider';
        riverpodProviderTypeParams = returnType.fullTypeName;
      }

      final String dependenciesConstModifier =
          dependencies == '<ProviderOrFamily>[]' ? 'const' : '';

      codeWriter
        ..writeln('@ProviderFor($functionName)')
        ..write('final $providerName = ')
        ..write('$riverpodProviderName<$riverpodProviderTypeParams>.internal(')
        ..write('$functionName,')
        ..write("name: r'$providerName',")
        ..write(
            "debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : $hashFunctionName,")
        ..write('dependencies: $dependenciesConstModifier $dependencies,')
        ..write(
            'allTransitiveDependencies: $dependenciesConstModifier $allTransitiveDependencies,')
        ..writeln(');')
        ..writeln();

      final String typedefRefName =
          '${functionName.camelCaseToPascalCase()}Ref';
      codeWriter
        ..writeln()
        ..writeln(
            'typedef $typedefRefName = ${riverpodProviderName}Ref<$riverpodProviderTypeParams>;')
        ..writeln();
    }

    for (final ClassDeclaration classDeclaration
        in buildInfo.compilationUnit.classDeclarations) {
      final AnnotationValueExtractor riverpodAnnotation =
          AnnotationValueExtractor(classDeclaration.metadata.firstWhereOrNull(
        (Annotation annotation) =>
            annotation.name.name.toLowerCase() == 'riverpod',
      ));

      if (!riverpodAnnotation.isValidAnnotation) {
        continue;
      }

      final String className = classDeclaration.name.lexeme;
      final MethodDeclaration? buildMethod = classDeclaration.methods
          .firstWhereOrNull(
              (MethodDeclaration element) => element.name.lexeme == 'build');

      if (buildMethod == null) {
        logger.error('Missing build method for riverpod provider "$className"');
        continue;
      }

      final (String dependencies, String allTransitiveDependencies) =
          _getDependenciesAndAllTransitiveDependencies(
              riverpodAnnotation: riverpodAnnotation);

      final String hashFunctionName =
          '_\$${className.pascalCaseToCamelCase()}Hash';

      codeWriter
        ..writeln("String $hashFunctionName() => r'${classDeclaration.sha1}';")
        ..writeln();

      if (buildMethod.parameters?.parameters.isNotEmpty ?? false) {
        _writeFamilyProviderForClass(
          codeWriter: codeWriter,
          classDeclaration: classDeclaration,
          riverpodAnnotation: riverpodAnnotation,
          buildMethod: buildMethod,
          hashFunctionName: hashFunctionName,
          dependencies: dependencies,
          allTransitiveDependencies: allTransitiveDependencies,
        );
        continue;
      }

      final bool isKeepAliveProvider =
          riverpodAnnotation.getBool('keepAlive') ?? false;

      final String providerName =
          '${className.pascalCaseToCamelCase()}Provider';

      final String riverpodProviderName;
      final String riverpodProviderTypeParams;
      final String riverpodNotifierName;
      final TachyonDartType returnType = buildMethod.returnType.customDartType;

      if (returnType.name == 'Future' || returnType.name == 'FutureOr') {
        riverpodProviderName = isKeepAliveProvider
            ? 'AsyncNotifierProvider'
            : 'AutoDisposeAsyncNotifierProvider';
        riverpodNotifierName =
            isKeepAliveProvider ? 'AsyncNotifier' : 'AutoDisposeAsyncNotifier';
        riverpodProviderTypeParams = returnType.typeArguments
            .map((TachyonDartType typeParam) => typeParam.fullTypeName)
            .join(', ');
      } else if (returnType.name == 'Stream') {
        riverpodProviderName = isKeepAliveProvider
            ? 'StreamNotifierProvider'
            : 'AutoDisposeStreamNotifierProvider';
        riverpodNotifierName = isKeepAliveProvider
            ? 'StreamNotifier'
            : 'AutoDisposeStreamNotifier';
        riverpodProviderTypeParams = returnType.typeArguments
            .map((TachyonDartType typeParam) => typeParam.fullTypeName)
            .join(', ');
      } else {
        riverpodProviderName = isKeepAliveProvider
            ? 'NotifierProvider'
            : 'AutoDisposeNotifierProvider';
        riverpodNotifierName =
            isKeepAliveProvider ? 'Notifier' : 'AutoDisposeNotifier';
        riverpodProviderTypeParams = returnType.fullTypeName;
      }

      final String dependenciesConstModifier =
          dependencies == '<ProviderOrFamily>[]' ? 'const' : '';

      codeWriter
        ..writeln('@ProviderFor($className)')
        ..write('final $providerName = ')
        ..write(
            '$riverpodProviderName<$className, $riverpodProviderTypeParams>.internal(')
        ..write('$className.new,')
        ..write("name: r'$providerName',")
        ..write(
            "debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : $hashFunctionName,")
        ..write('dependencies: $dependenciesConstModifier $dependencies,')
        ..write(
            'allTransitiveDependencies: $dependenciesConstModifier $allTransitiveDependencies,')
        ..writeln(');')
        ..writeln();

      codeWriter
        ..writeln()
        ..writeln(
            'typedef _\$$className = $riverpodNotifierName<$riverpodProviderTypeParams>;')
        ..writeln();
    }

    return codeWriter.content;
  }

  void _writeFamilyProviderForClass({
    required final CodeWriter codeWriter,
    required final ClassDeclaration classDeclaration,
    required final AnnotationValueExtractor riverpodAnnotation,
    required final MethodDeclaration buildMethod,
    required final String hashFunctionName,
    required final String dependencies,
    required final String allTransitiveDependencies,
  }) {
    final String className = classDeclaration.name.lexeme;
    final TachyonDartType returnType = buildMethod.returnType.customDartType;

    final Object parametersSourceCode = buildMethod.parameters ?? '()';
    final List<FormalParameter> parameters =
        buildMethod.parameters?.parameters ?? <FormalParameter>[];

    final String parametersCodeForHash =
        parameters.map((FormalParameter p) => p.name!.lexeme).join(',');

    final String parametersCodeForEquality =
        parameters.map((FormalParameter p) {
      final String paramName = p.name!.lexeme;
      return 'other.$paramName == $paramName';
    }).join(' && ');

    final String parametersAsFields = parameters.map((FormalParameter p) {
      final TachyonDartType type = switch (p) {
        SimpleFormalParameter() => p.type.customDartType,
        DefaultFormalParameter() =>
          (p.parameter as SimpleFormalParameter).type.customDartType,
        _ => TachyonDartType.dynamic,
      };
      return 'late final ${type.fullTypeName} ${p.name!.lexeme};';
    }).join('\n\n');

    final String parametersAsArguments = parameters.map((FormalParameter p) {
      return switch (p) {
        DefaultFormalParameter() => '${p.name!.lexeme}: ${p.name!.lexeme}',
        _ => p.name!.lexeme,
      };
    }).join(',');

    final String parametersWithProviderAsArguments =
        parameters.map((FormalParameter p) {
      return switch (p) {
        DefaultFormalParameter() =>
          '${p.name!.lexeme}: provider.${p.name!.lexeme}',
        _ => 'provider.${p.name!.lexeme}',
      };
    }).join(',');

    final String parametersAsNamedArguments =
        parameters.map((FormalParameter p) {
      final String name = p.name!.lexeme;
      return '$name: $name';
    }).join(',');

    final String parametersAsCascadeArguments =
        parameters.map((FormalParameter p) {
      final String name = p.name!.lexeme;
      return '..$name = $name';
    }).join();

    final String parametersAsRequiredArguments =
        parameters.map((FormalParameter p) {
      final String name = p.name!.lexeme;
      return 'required this.$name';
    }).join(',');

    final String parametersAsGetters = parameters.map((FormalParameter p) {
      final TachyonDartType type = switch (p) {
        SimpleFormalParameter() => p.type.customDartType,
        _ => TachyonDartType.dynamic,
      };
      return '${type.fullTypeName} get ${p.name!.lexeme};';
    }).join('\n\n');

    final String providerName = '${className}Provider';
    final String familyName = '${className}Family';

    final String buildlessNotifierName;
    final String providerGenericArgument;
    final String familyGenericArgument;
    final String notifierType;

    final bool isKeepAlive = riverpodAnnotation.getBool('keepAlive') ?? false;
    final String notifierPrefix = isKeepAlive ? '' : 'AutoDispose';

    if (returnType.name == 'Future' || returnType.name == 'FutureOr') {
      notifierType = '${notifierPrefix}AsyncNotifier';
      buildlessNotifierName = 'Buildless$notifierType';
      final String returnTypeTypeParams = returnType.typeArguments
          .map((TachyonDartType type) => type.fullTypeName)
          .join(', ');
      providerGenericArgument = returnTypeTypeParams;
      familyGenericArgument = 'AsyncValue<$providerGenericArgument>';
    } else if (returnType.name == 'Stream') {
      notifierType = '${notifierPrefix}StreamNotifier';
      buildlessNotifierName = 'Buildless$notifierType';
      final String returnTypeTypeParams = returnType.typeArguments
          .map((TachyonDartType type) => type.fullTypeName)
          .join(', ');
      providerGenericArgument = returnTypeTypeParams;
      familyGenericArgument = 'AsyncValue<$providerGenericArgument>';
    } else {
      notifierType = '${notifierPrefix}Notifier';
      buildlessNotifierName = 'Buildless$notifierType';
      providerGenericArgument = returnType.fullTypeName;
      familyGenericArgument = providerGenericArgument;
    }

    final String parametersAsImplementedGetters =
        parameters.map((FormalParameter p) {
      final TachyonDartType type = switch (p) {
        SimpleFormalParameter() => p.type.customDartType,
        _ => TachyonDartType.dynamic,
      };
      final String variableName = p.name!.lexeme;
      return '''
@override
${type.fullTypeName} get $variableName => (origin as $providerName).$variableName;
''';
    }).join('\n\n');

    final String dependenciesConstOrFinalModifier =
        (dependencies == 'null' || dependencies == '<ProviderOrFamily>[]')
            ? 'const'
            : 'final';

    codeWriter.writeln('''
abstract class _\$$className
    extends $buildlessNotifierName<$providerGenericArgument> {
  $parametersAsFields

  ${returnType.fullTypeName} build$parametersSourceCode;
}''');

    codeWriter.writeln('''
@ProviderFor($className)
const ${className.pascalCaseToCamelCase()}Provider = $familyName();
''');

    codeWriter.writeln('''
class $familyName extends Family<$familyGenericArgument> {
  const $familyName();

  $providerName call$parametersSourceCode {
    return $providerName($parametersAsArguments);
  }

  @visibleForOverriding
  @override
  $providerName getProviderOverride(
    covariant $providerName provider,
  ) {
    return call($parametersWithProviderAsArguments);
  }

  static $dependenciesConstOrFinalModifier Iterable<ProviderOrFamily>? _dependencies = 
    $dependencies;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static $dependenciesConstOrFinalModifier Iterable<ProviderOrFamily>? _allTransitiveDependencies = 
    $allTransitiveDependencies;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'${className.pascalCaseToCamelCase()}Provider';
}
''');

    codeWriter.writeln('''
class $providerName
    extends ${notifierType}ProviderImpl<$className, $providerGenericArgument> {
  $providerName$parametersSourceCode : this._internal(
          () => $className()$parametersAsCascadeArguments,
          from: ${providerName.pascalCaseToCamelCase()},
          name: r'${providerName.pascalCaseToCamelCase()}',
          debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : $hashFunctionName,
          dependencies: $familyName._dependencies,
          allTransitiveDependencies:
              $familyName._allTransitiveDependencies,
          $parametersAsNamedArguments,
        );

  $providerName._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    $parametersAsRequiredArguments,
  }) : super.internal();

  $parametersAsFields

  @override
  ${returnType.fullTypeName} runNotifierBuild(
    covariant $className notifier,
  ) {
    return notifier.build($parametersAsArguments);
  }

  @override
  Override overrideWith($className Function() create) {
    return ProviderOverride(
      origin: this,
      override: $providerName._internal(
        () => create()$parametersAsCascadeArguments,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        $parametersAsNamedArguments,
      ),
    );
  }

  @override
  (${familyParametersAsRecordSourceCode(parameters)}) get argument {
    return ($parametersAsArguments,);
  }

  @override
  ${notifierType}ProviderElement<$className, $providerGenericArgument>
      createElement() {
    return _${providerName}Element(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is $providerName && 
      runtimeType == other.runtimeType &&
      $parametersCodeForEquality;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      $parametersCodeForHash,
    ]);
  }
}
''');

    codeWriter.writeln('''
mixin ${providerName}Ref on ${notifierType}ProviderRef<$providerGenericArgument> {
  $parametersAsGetters
}
''');

    codeWriter.writeln('''
class _${providerName}Element
    extends ${notifierType}ProviderElement<$className, $providerGenericArgument>
    with ${providerName}Ref {
  _${providerName}Element(super.provider);

  $parametersAsImplementedGetters
}
''');
  }

  void _writeFamilyProviderForFunction({
    required final CodeWriter codeWriter,
    required final FunctionDeclaration functionDeclaration,
    required final AnnotationValueExtractor riverpodAnnotation,
    required final String hashFunctionName,
    required final String dependencies,
    required final String allTransitiveDependencies,
  }) {
    final String functionName = functionDeclaration.name.lexeme;
    final TachyonDartType returnType =
        functionDeclaration.returnType.customDartType;

    final String parametersSourceCode =
        (functionDeclaration.functionExpression.parameters?.toSource() ?? '()')
            .replaceFirst(RegExp(r'[^\(].*?,\s*'), '');

    final List<FormalParameter> parameters = functionDeclaration
            .functionExpression.parameters?.parameters
            .sublist(1) ??
        <FormalParameter>[];

    final String parametersCodeForHash =
        parameters.map((FormalParameter p) => p.name!.lexeme).join(',');

    final String parametersCodeForEquality =
        parameters.map((FormalParameter p) {
      final String paramName = p.name!.lexeme;
      return 'other.$paramName == $paramName';
    }).join(' && ');

    final String parametersAsFields = parameters.map((FormalParameter p) {
      final TachyonDartType type = switch (p) {
        DefaultFormalParameter() =>
          (p.parameter as SimpleFormalParameter).type.customDartType,
        SimpleFormalParameter() => p.type.customDartType,
        _ => TachyonDartType.dynamic,
      };
      return 'final ${type.fullTypeName} ${p.name!.lexeme};';
    }).join('\n\n');

    final String parametersAsArguments = parameters.map((FormalParameter p) {
      return switch (p) {
        DefaultFormalParameter() => '${p.name!.lexeme}: ${p.name!.lexeme}',
        _ => p.name!.lexeme,
      };
    }).join(',');

    final String parametersWithProviderAsArguments =
        parameters.map((FormalParameter p) {
      return switch (p) {
        DefaultFormalParameter() =>
          '${p.name!.lexeme}: provider.${p.name!.lexeme}',
        _ => 'provider.${p.name!.lexeme}',
      };
    }).join(',');

    final String parametersAsNamedArguments =
        parameters.map((FormalParameter p) {
      final String name = p.name!.lexeme;
      return '$name: $name';
    }).join(',');

    final String parametersAsRequiredArguments =
        parameters.map((FormalParameter p) {
      final String name = p.name!.lexeme;
      return 'required this.$name';
    }).join(',');

    final String parametersAsGetters = parameters.map((FormalParameter p) {
      final TachyonDartType type = switch (p) {
        SimpleFormalParameter() => p.type.customDartType,
        _ => TachyonDartType.dynamic,
      };
      return '${type.fullTypeName} get ${p.name!.lexeme};';
    }).join('\n\n');

    final String providerName =
        '${functionName.camelCaseToPascalCase()}Provider';
    final String familyName = '${functionName.camelCaseToPascalCase()}Family';
    final String refName = '${functionName.camelCaseToPascalCase()}Ref';

    final String providerGenericArgument;
    final String familyGenericArgument;
    final String providerType;

    final bool isKeepAlive = riverpodAnnotation.getBool('keepAlive') ?? false;
    final String notifierPrefix = isKeepAlive ? '' : 'AutoDispose';

    final String returnTypeTypeParams = returnType.typeArguments
        .map((TachyonDartType type) => type.fullTypeName)
        .join(', ');

    String overrideWithFunctionParameterReturnType = returnType.fullTypeName;

    if (returnType.name == 'Future' || returnType.name == 'FutureOr') {
      overrideWithFunctionParameterReturnType =
          'FutureOr<$returnTypeTypeParams>';
      providerType = '${notifierPrefix}Future';
      providerGenericArgument = returnTypeTypeParams;
      familyGenericArgument = 'AsyncValue<$providerGenericArgument>';
    } else if (returnType.name == 'Stream') {
      providerType = '${notifierPrefix}Stream';
      providerGenericArgument = returnTypeTypeParams;
      familyGenericArgument = 'AsyncValue<$providerGenericArgument>';
    } else {
      providerType = notifierPrefix;
      providerGenericArgument = returnType.fullTypeName;
      familyGenericArgument = providerGenericArgument;
    }

    final String parametersAsImplementedGetters =
        parameters.map((FormalParameter p) {
      final TachyonDartType type = switch (p) {
        SimpleFormalParameter() => p.type.customDartType,
        _ => TachyonDartType.dynamic,
      };
      final String variableName = p.name!.lexeme;
      return '''
@override
${type.fullTypeName} get $variableName => (origin as $providerName).$variableName;
''';
    }).join('\n\n');

    final String dependenciesConstOrFinalModifier =
        (dependencies == 'null' || dependencies == '<ProviderOrFamily>[]')
            ? 'const'
            : 'final';

    codeWriter.writeln('''
@ProviderFor($functionName)
const ${functionName}Provider = $familyName();
''');

    codeWriter.writeln('''
class $familyName extends Family<$familyGenericArgument> {
  const $familyName();

  $providerName call$parametersSourceCode {
    return $providerName($parametersAsArguments,);
  }

  @visibleForOverriding
  @override
  $providerName getProviderOverride(
    covariant $providerName provider,
  ) {
    return call($parametersWithProviderAsArguments);
  }

  static $dependenciesConstOrFinalModifier Iterable<ProviderOrFamily>? _dependencies = 
    $dependencies;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static $dependenciesConstOrFinalModifier Iterable<ProviderOrFamily>? _allTransitiveDependencies = 
    $allTransitiveDependencies;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'${functionName}Provider';
}
''');

    codeWriter.writeln('''
class $providerName
    extends ${providerType}Provider<$providerGenericArgument> {
  $providerName$parametersSourceCode : this._internal(
          (ref) => $functionName(
            ref as $refName,
            $parametersAsArguments
          ),
          from: ${providerName.pascalCaseToCamelCase()},
          name: r'${providerName.pascalCaseToCamelCase()}',
          debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : $hashFunctionName,
          dependencies: $familyName._dependencies,
          allTransitiveDependencies:
              $familyName._allTransitiveDependencies,
          $parametersAsNamedArguments,
        );

  $providerName._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    $parametersAsRequiredArguments,
  }) : super.internal();

  $parametersAsFields

  @override
  Override overrideWith($overrideWithFunctionParameterReturnType Function($refName provider) create) {
    return ProviderOverride(
      origin: this,
      override: $providerName._internal(
        (ref) => create(ref as $refName),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        $parametersAsNamedArguments,
      ),
    );
  }

  @override
  (${familyParametersAsRecordSourceCode(parameters)}) get argument {
    return ($parametersAsArguments,);
  }

  @override
  ${providerType}ProviderElement<$providerGenericArgument>
      createElement() {
    return _${providerName}Element(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is $providerName && 
      runtimeType == other.runtimeType &&
      $parametersCodeForEquality;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      $parametersCodeForHash,
    ]);
  }
}
''');

    codeWriter.writeln('''
mixin $refName on ${providerType}ProviderRef<$providerGenericArgument> {
  $parametersAsGetters
}
''');

    codeWriter.writeln('''
class _${providerName}Element
    extends ${providerType}ProviderElement<$providerGenericArgument>
    with $refName {
  _${providerName}Element(super.provider);

  $parametersAsImplementedGetters
}
''');
  }

  (String, String) _getDependenciesAndAllTransitiveDependencies({
    required final AnnotationValueExtractor riverpodAnnotation,
  }) {
    StringBuffer dependencies = StringBuffer();
    StringBuffer allTransitiveDependencies = StringBuffer();

    if (riverpodAnnotation.getNamedArgument('dependencies')
        case NamedExpression depsExpr) {
      if (depsExpr.expression case ListLiteral depsListLiteral) {
        dependencies.write('<ProviderOrFamily>[');
        allTransitiveDependencies.write('<ProviderOrFamily>{');
        for (final child in depsListLiteral.childEntities) {
          if (child is! Identifier) {
            continue;
          }
          dependencies.write('${child.name}Provider,');
          allTransitiveDependencies.write('${child.name}Provider,');
          allTransitiveDependencies
              .write('...?${child.name}Provider.allTransitiveDependencies,');
        }
        dependencies.write(']');
        allTransitiveDependencies.write('}');
      }
    } else {
      dependencies.write('null');
      allTransitiveDependencies.write('null');
    }
    return (dependencies.toString(), allTransitiveDependencies.toString());
  }

  String familyParametersAsRecordSourceCode(List<FormalParameter> parameters) {
    StringBuffer parametersTypesForRecord = StringBuffer();

    bool foundNamedParameter = false;
    for (final p in parameters) {
      if (p is SimpleFormalParameter) {
        parametersTypesForRecord
          ..write(p.type.customDartType.fullTypeName)
          ..write(',');
      } else if (p is DefaultFormalParameter) {
        if (!foundNamedParameter) {
          foundNamedParameter = true;
          parametersTypesForRecord.write('{');
        }

        parametersTypesForRecord
          ..write((p.parameter as SimpleFormalParameter)
              .type
              .customDartType
              .fullTypeName)
          ..write(' ')
          ..write(p.name!.lexeme)
          ..write(',');
      }
    }

    if (foundNamedParameter) {
      parametersTypesForRecord.write('}');
    }

    return parametersTypesForRecord.toString();
  }
}

extension on String {
  String pascalCaseToCamelCase() {
    return replaceFirstMapped(RegExp(r'([A-Z])'), (Match match) {
      return match[0]?.toLowerCase() ?? '';
    });
  }

  String camelCaseToPascalCase() {
    return replaceFirstMapped(RegExp(r'([a-z])'), (Match match) {
      return match[0]?.toUpperCase() ?? '';
    });
  }
}

extension on AstNode {
  String get sha1 {
    return crypto.sha1.convert(utf8.encode(toSource())).toString();
  }
}
