class NumberToWord {
  final List<String> units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];
  final List<String> tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  String convert(int number) {
    if (number == 0) return 'Zero';
    return _convert(number);
  }

  String _convert(int number) {
    if (number < 20) return units[number];
    if (number < 100) {
      return '${tens[number ~/ 10]} ${units[number % 10]}'.trim();
    }
    if (number < 1000) {
      return '${units[number ~/ 100]} Hundred ${_convert(number % 100)}'.trim();
    }
    if (number < 100000) {
      return '${_convert(number ~/ 1000)} Thousand ${_convert(number % 1000)}'
          .trim();
    }
    if (number < 10000000) {
      return '${_convert(number ~/ 100000)} Lakh ${_convert(number % 100000)}'
          .trim();
    }
    return '${_convert(number ~/ 10000000)} Crore ${_convert(number % 10000000)}'
        .trim();
  }
}
