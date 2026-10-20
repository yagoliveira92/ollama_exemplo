import '../../domain/models/agent_result.dart';

class FirewallSanitizer {
  // Regex padrão para PIIs comuns brasileiras e globais
  static final RegExp _cpfRegex = RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b');
  static final RegExp _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );
  static final RegExp _creditCardRegex = RegExp(r'\b(?:\d{4}[ -]?){3}\d{4}\b');
  static final RegExp _phoneRegex = RegExp(
    r'\b(?:\+?55\s?)?(?:\(?\d{2}\)?\s?)?(?:9\d{4}|\d{4})[-.\s]?\d{4}\b',
  );
  static final RegExp _clientNameRegex = RegExp(
    r'\b(?:Cliente|Usuário|Usuario|Paciente|Funcionário|Funcionario)\s+([A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+(?:\s+[A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ][a-záéíóúâêîôûãõç]+)+)',
    caseSensitive: true,
  );

  /// Executa o Firewall Cognitivo local para sanitizar o texto antes de qualquer saída
  PrivacyReport sanitize(String rawText) {
    String currentText = rawText;
    final List<PiiItem> detected = [];

    // 1. Anonimização de Nomes de Clientes contextuais
    currentText = currentText.replaceAllMapped(_clientNameRegex, (match) {
      final whole = match.group(0)!;
      final nameOnly = match.group(1)!;
      detected.add(PiiItem(
        category: 'Nome Pessoal',
        originalValue: nameOnly,
        maskedValue: '[NOME_ANONIMIZADO]',
      ));
      return whole.replaceFirst(nameOnly, '[NOME_ANONIMIZADO]');
    });

    // 2. Anonimização de CPFs
    currentText = currentText.replaceAllMapped(_cpfRegex, (match) {
      final value = match.group(0)!;
      detected.add(PiiItem(
        category: 'Documento CPF',
        originalValue: value,
        maskedValue: '[CPF_PROTEGIDO]',
      ));
      return '[CPF_PROTEGIDO]';
    });

    // 3. Anonimização de E-mails
    currentText = currentText.replaceAllMapped(_emailRegex, (match) {
      final value = match.group(0)!;
      detected.add(PiiItem(
        category: 'Endereço E-mail',
        originalValue: value,
        maskedValue: '[EMAIL_PROTEGIDO]',
      ));
      return '[EMAIL_PROTEGIDO]';
    });

    // 4. Anonimização de Cartões de Crédito
    currentText = currentText.replaceAllMapped(_creditCardRegex, (match) {
      final value = match.group(0)!;
      detected.add(PiiItem(
        category: 'Cartão de Pagamento',
        originalValue: value,
        maskedValue: '[CARTAO_PROTEGIDO]',
      ));
      return '[CARTAO_PROTEGIDO]';
    });

    // 5. Anonimização de Telefones
    currentText = currentText.replaceAllMapped(_phoneRegex, (match) {
      final value = match.group(0)!;
      detected.add(PiiItem(
        category: 'Telefone Contato',
        originalValue: value,
        maskedValue: '[TELEFONE_PROTEGIDO]',
      ));
      return '[TELEFONE_PROTEGIDO]';
    });

    return PrivacyReport(
      hasPii: detected.isNotEmpty,
      detectedPii: detected,
      originalText: rawText,
      sanitizedText: currentText,
    );
  }

  /// Verifica se o texto possui indícios de PII sem precisar reconstruí-lo por completo
  bool containsPii(String text) {
    return _cpfRegex.hasMatch(text) ||
        _emailRegex.hasMatch(text) ||
        _creditCardRegex.hasMatch(text) ||
        _phoneRegex.hasMatch(text) ||
        _clientNameRegex.hasMatch(text);
  }
}
