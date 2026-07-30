/// Motor de ajedrez puro en Dart. Sin dependencias externas.
/// Representa el tablero como una lista de 64 casillas (índice 0 = a1 ... 63 = h8).
library chess_engine;

class ChessMove {
  final int from;
  final int to;
  final String? promotion; // 'Q','R','B','N'
  final bool isCastleKingSide;
  final bool isCastleQueenSide;
  final bool isEnPassant;
  final String? capturedPiece;
  final String movedPiece;

  ChessMove({
    required this.from,
    required this.to,
    required this.movedPiece,
    this.promotion,
    this.isCastleKingSide = false,
    this.isCastleQueenSide = false,
    this.isEnPassant = false,
    this.capturedPiece,
  });

  String get uci =>
      '${ChessEngine.squareName(from)}${ChessEngine.squareName(to)}${promotion != null ? promotion!.toLowerCase() : ''}';
}

class ChessEngine {
  /// board[i] es null (vacío) o un código de dos letras: color + tipo.
  /// color: 'w' o 'b'. tipo: 'P','N','B','R','Q','K'.
  List<String?> board = List.filled(64, null);
  String turn = 'w';
  bool whiteCanCastleK = true;
  bool whiteCanCastleQ = true;
  bool blackCanCastleK = true;
  bool blackCanCastleQ = true;
  int? enPassantTarget; // índice de casilla capturable al paso, o null
  int halfMoveClock = 0;
  int fullMoveNumber = 1;

  final List<String> _history = []; // pila de FEN para deshacer
  final List<String> sanHistory = [];

  ChessEngine() {
    loadFen(startFen);
  }

  static const String startFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  static int fileOf(int sq) => sq % 8;
  static int rankOf(int sq) => sq ~/ 8;
  static int squareAt(int file, int rank) => rank * 8 + file;
  static bool onBoard(int file, int rank) =>
      file >= 0 && file < 8 && rank >= 0 && rank < 8;

  static String squareName(int sq) {
    final f = String.fromCharCode('a'.codeUnitAt(0) + fileOf(sq));
    final r = (rankOf(sq) + 1).toString();
    return '$f$r';
  }

  static int squareIndex(String name) {
    final f = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final r = int.parse(name.substring(1)) - 1;
    return squareAt(f, r);
  }

  // ---------------- FEN ----------------

  void loadFen(String fen) {
    board = List.filled(64, null);
    final parts = fen.trim().split(' ');
    final rows = parts[0].split('/'); // rows[0] = rank8 ... rows[7] = rank1
    for (int r = 0; r < 8; r++) {
      final rank = 7 - r; // fen row 0 -> rank 8 (índice 7)
      int file = 0;
      for (final ch in rows[r].split('')) {
        if (RegExp(r'\d').hasMatch(ch)) {
          file += int.parse(ch);
        } else {
          final color = ch.toUpperCase() == ch ? 'w' : 'b';
          final type = ch.toUpperCase();
          board[squareAt(file, rank)] = '$color$type';
          file++;
        }
      }
    }
    turn = parts.length > 1 ? parts[1] : 'w';
    final castling = parts.length > 2 ? parts[2] : '-';
    whiteCanCastleK = castling.contains('K');
    whiteCanCastleQ = castling.contains('Q');
    blackCanCastleK = castling.contains('k');
    blackCanCastleQ = castling.contains('q');
    final ep = parts.length > 3 ? parts[3] : '-';
    enPassantTarget = ep == '-' ? null : squareIndex(ep);
    halfMoveClock = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
    fullMoveNumber = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;
  }

  String toFen() {
    final buffer = StringBuffer();
    for (int r = 7; r >= 0; r--) {
      int empty = 0;
      for (int f = 0; f < 8; f++) {
        final piece = board[squareAt(f, r)];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            buffer.write(empty);
            empty = 0;
          }
          final color = piece[0];
          final type = piece[1];
          buffer.write(color == 'w' ? type : type.toLowerCase());
        }
      }
      if (empty > 0) buffer.write(empty);
      if (r > 0) buffer.write('/');
    }
    buffer.write(' $turn ');
    String castling = '';
    if (whiteCanCastleK) castling += 'K';
    if (whiteCanCastleQ) castling += 'Q';
    if (blackCanCastleK) castling += 'k';
    if (blackCanCastleQ) castling += 'q';
    buffer.write(castling.isEmpty ? '-' : castling);
    buffer.write(' ');
    buffer.write(enPassantTarget == null ? '-' : squareName(enPassantTarget!));
    buffer.write(' $halfMoveClock $fullMoveNumber');
    return buffer.toString();
  }

  // ---------------- Consultas ----------------

  String? pieceAt(int sq) => board[sq];
  String colorAt(int sq) => board[sq]?[0] ?? '';
  String typeAt(int sq) => board[sq]?[1] ?? '';

  int findKing(String color) {
    for (int i = 0; i < 64; i++) {
      if (board[i] == '${color}K') return i;
    }
    return -1;
  }

  bool isSquareAttacked(int sq, String byColor) {
    // Peones
    final dir = byColor == 'w' ? -1 : 1; // atacante viene desde esa dirección
    for (final df in [-1, 1]) {
      final f = fileOf(sq) + df;
      final r = rankOf(sq) + dir;
      if (onBoard(f, r)) {
        final s = squareAt(f, r);
        if (board[s] == '${byColor}P') return true;
      }
    }
    // Caballos
    const knightDeltas = [
      [1, 2], [2, 1], [-1, 2], [-2, 1],
      [1, -2], [2, -1], [-1, -2], [-2, -1]
    ];
    for (final d in knightDeltas) {
      final f = fileOf(sq) + d[0];
      final r = rankOf(sq) + d[1];
      if (onBoard(f, r) && board[squareAt(f, r)] == '${byColor}N') return true;
    }
    // Rey
    for (int df = -1; df <= 1; df++) {
      for (int dr = -1; dr <= 1; dr++) {
        if (df == 0 && dr == 0) continue;
        final f = fileOf(sq) + df;
        final r = rankOf(sq) + dr;
        if (onBoard(f, r) && board[squareAt(f, r)] == '${byColor}K') return true;
      }
    }
    // Deslizantes: torre/dama
    const rookDirs = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    for (final d in rookDirs) {
      int f = fileOf(sq) + d[0];
      int r = rankOf(sq) + d[1];
      while (onBoard(f, r)) {
        final s = squareAt(f, r);
        final p = board[s];
        if (p != null) {
          if (p[0] == byColor && (p[1] == 'R' || p[1] == 'Q')) return true;
          break;
        }
        f += d[0];
        r += d[1];
      }
    }
    // Deslizantes: alfil/dama
    const bishopDirs = [[1, 1], [1, -1], [-1, 1], [-1, -1]];
    for (final d in bishopDirs) {
      int f = fileOf(sq) + d[0];
      int r = rankOf(sq) + d[1];
      while (onBoard(f, r)) {
        final s = squareAt(f, r);
        final p = board[s];
        if (p != null) {
          if (p[0] == byColor && (p[1] == 'B' || p[1] == 'Q')) return true;
          break;
        }
        f += d[0];
        r += d[1];
      }
    }
    return false;
  }

  bool isInCheck(String color) {
    final k = findKing(color);
    if (k == -1) return false;
    final opponent = color == 'w' ? 'b' : 'w';
    return isSquareAttacked(k, opponent);
  }

  // ---------------- Generación de movimientos ----------------

  /// Movimientos pseudo-legales (sin filtrar jaques propios) para una casilla.
  List<ChessMove> _pseudoMovesFrom(int sq) {
    final piece = board[sq];
    if (piece == null) return [];
    final color = piece[0];
    final type = piece[1];
    final moves = <ChessMove>[];
    final f0 = fileOf(sq);
    final r0 = rankOf(sq);

    void addIfValid(int f, int r, {bool onlyCapture = false, bool onlyQuiet = false}) {
      if (!onBoard(f, r)) return;
      final target = squareAt(f, r);
      final targetPiece = board[target];
      if (onlyQuiet && targetPiece != null) return;
      if (onlyCapture && targetPiece == null) return;
      if (targetPiece != null && targetPiece[0] == color) return;
      moves.add(ChessMove(
        from: sq,
        to: target,
        movedPiece: piece,
        capturedPiece: targetPiece,
      ));
    }

    if (type == 'P') {
      final dir = color == 'w' ? 1 : -1;
      final startRank = color == 'w' ? 1 : 6;
      final promoRank = color == 'w' ? 7 : 0;
      // avance simple
      if (onBoard(f0, r0 + dir) && board[squareAt(f0, r0 + dir)] == null) {
        final target = squareAt(f0, r0 + dir);
        if (rankOf(target) == promoRank) {
          for (final promo in ['Q', 'R', 'B', 'N']) {
            moves.add(ChessMove(from: sq, to: target, movedPiece: piece, promotion: promo));
          }
        } else {
          moves.add(ChessMove(from: sq, to: target, movedPiece: piece));
        }
        // avance doble
        if (r0 == startRank && board[squareAt(f0, r0 + 2 * dir)] == null) {
          moves.add(ChessMove(from: sq, to: squareAt(f0, r0 + 2 * dir), movedPiece: piece));
        }
      }
      // capturas diagonales
      for (final df in [-1, 1]) {
        final f = f0 + df;
        final r = r0 + dir;
        if (!onBoard(f, r)) continue;
        final target = squareAt(f, r);
        final targetPiece = board[target];
        if (targetPiece != null && targetPiece[0] != color) {
          if (rankOf(target) == promoRank) {
            for (final promo in ['Q', 'R', 'B', 'N']) {
              moves.add(ChessMove(
                  from: sq, to: target, movedPiece: piece, promotion: promo, capturedPiece: targetPiece));
            }
          } else {
            moves.add(ChessMove(from: sq, to: target, movedPiece: piece, capturedPiece: targetPiece));
          }
        } else if (enPassantTarget != null && target == enPassantTarget) {
          moves.add(ChessMove(
            from: sq,
            to: target,
            movedPiece: piece,
            isEnPassant: true,
            capturedPiece: '${color == 'w' ? 'b' : 'w'}P',
          ));
        }
      }
    } else if (type == 'N') {
      const deltas = [
        [1, 2], [2, 1], [-1, 2], [-2, 1],
        [1, -2], [2, -1], [-1, -2], [-2, -1]
      ];
      for (final d in deltas) {
        addIfValid(f0 + d[0], r0 + d[1]);
      }
    } else if (type == 'K') {
      for (int df = -1; df <= 1; df++) {
        for (int dr = -1; dr <= 1; dr++) {
          if (df == 0 && dr == 0) continue;
          addIfValid(f0 + df, r0 + dr);
        }
      }
      // Enroque
      final opponent = color == 'w' ? 'b' : 'w';
      if (!isSquareAttacked(sq, opponent)) {
        final rank = color == 'w' ? 0 : 7;
        final canK = color == 'w' ? whiteCanCastleK : blackCanCastleK;
        final canQ = color == 'w' ? whiteCanCastleQ : blackCanCastleQ;
        if (canK &&
            board[squareAt(5, rank)] == null &&
            board[squareAt(6, rank)] == null &&
            board[squareAt(7, rank)] == '${color}R' &&
            !isSquareAttacked(squareAt(5, rank), opponent) &&
            !isSquareAttacked(squareAt(6, rank), opponent)) {
          moves.add(ChessMove(
              from: sq, to: squareAt(6, rank), movedPiece: piece, isCastleKingSide: true));
        }
        if (canQ &&
            board[squareAt(1, rank)] == null &&
            board[squareAt(2, rank)] == null &&
            board[squareAt(3, rank)] == null &&
            board[squareAt(0, rank)] == '${color}R' &&
            !isSquareAttacked(squareAt(2, rank), opponent) &&
            !isSquareAttacked(squareAt(3, rank), opponent)) {
          moves.add(ChessMove(
              from: sq, to: squareAt(2, rank), movedPiece: piece, isCastleQueenSide: true));
        }
      }
    } else {
      List<List<int>> dirs = [];
      if (type == 'R' || type == 'Q') {
        dirs.addAll([[1, 0], [-1, 0], [0, 1], [0, -1]]);
      }
      if (type == 'B' || type == 'Q') {
        dirs.addAll([[1, 1], [1, -1], [-1, 1], [-1, -1]]);
      }
      for (final d in dirs) {
        int f = f0 + d[0];
        int r = r0 + d[1];
        while (onBoard(f, r)) {
          final target = squareAt(f, r);
          final targetPiece = board[target];
          if (targetPiece == null) {
            moves.add(ChessMove(from: sq, to: target, movedPiece: piece));
          } else {
            if (targetPiece[0] != color) {
              moves.add(ChessMove(from: sq, to: target, movedPiece: piece, capturedPiece: targetPiece));
            }
            break;
          }
          f += d[0];
          r += d[1];
        }
      }
    }
    return moves;
  }

  /// Movimientos legales desde una casilla (filtra los que dejan al propio rey en jaque).
  List<ChessMove> legalMovesFrom(int sq) {
    final piece = board[sq];
    if (piece == null) return [];
    final color = piece[0];
    final pseudo = _pseudoMovesFrom(sq);
    final legal = <ChessMove>[];
    for (final m in pseudo) {
      final snapshot = toFen();
      _applyMoveRaw(m);
      if (!isInCheck(color)) legal.add(m);
      loadFen(snapshot);
    }
    return legal;
  }

  /// Todos los movimientos legales del jugador en turno.
  List<ChessMove> allLegalMoves() {
    final all = <ChessMove>[];
    for (int i = 0; i < 64; i++) {
      final p = board[i];
      if (p != null && p[0] == turn) {
        all.addAll(legalMovesFrom(i));
      }
    }
    return all;
  }

  bool get isCheckmate => isInCheck(turn) && allLegalMoves().isEmpty;
  bool get isStalemate => !isInCheck(turn) && allLegalMoves().isEmpty;
  bool get isGameOver => isCheckmate || isStalemate || halfMoveClock >= 100;

  // ---------------- Aplicar movimiento ----------------

  void _applyMoveRaw(ChessMove m) {
    final piece = board[m.from];
    board[m.from] = null;
    board[m.to] = m.promotion != null ? '${piece![0]}${m.promotion}' : piece;

    if (m.isEnPassant) {
      final capturedSq = squareAt(fileOf(m.to), rankOf(m.from));
      board[capturedSq] = null;
    }
    if (m.isCastleKingSide) {
      final rank = rankOf(m.from);
      board[squareAt(5, rank)] = board[squareAt(7, rank)];
      board[squareAt(7, rank)] = null;
    }
    if (m.isCastleQueenSide) {
      final rank = rankOf(m.from);
      board[squareAt(3, rank)] = board[squareAt(0, rank)];
      board[squareAt(0, rank)] = null;
    }
  }

  /// Ejecuta el movimiento de forma completa: actualiza turno, enroques, en passant, historial.
  /// Devuelve false si el movimiento no es legal.
  bool makeMove(int from, int to, {String? promotion}) {
    final legal = legalMovesFrom(from);
    ChessMove? chosen;
    for (final m in legal) {
      if (m.to == to && (m.promotion == promotion || (m.promotion != null && promotion == null && m.promotion == 'Q'))) {
        chosen = m;
        break;
      }
    }
    chosen ??= legal.where((m) => m.to == to).isNotEmpty ? legal.firstWhere((m) => m.to == to) : null;
    if (chosen == null) return false;

    _history.add(toFen());
    final piece = board[from]!;
    final color = piece[0];
    final type = piece[1];

    _applyMoveRaw(chosen);

    // Derechos de enroque
    if (type == 'K') {
      if (color == 'w') {
        whiteCanCastleK = false;
        whiteCanCastleQ = false;
      } else {
        blackCanCastleK = false;
        blackCanCastleQ = false;
      }
    }
    if (from == squareIndex('a1') || to == squareIndex('a1')) whiteCanCastleQ = false;
    if (from == squareIndex('h1') || to == squareIndex('h1')) whiteCanCastleK = false;
    if (from == squareIndex('a8') || to == squareIndex('a8')) blackCanCastleQ = false;
    if (from == squareIndex('h8') || to == squareIndex('h8')) blackCanCastleK = false;

    // En passant target
    if (type == 'P' && (rankOf(to) - rankOf(from)).abs() == 2) {
      enPassantTarget = squareAt(fileOf(from), (rankOf(from) + rankOf(to)) ~/ 2);
    } else {
      enPassantTarget = null;
    }

    // Reloj de medio movimiento
    if (type == 'P' || chosen.capturedPiece != null) {
      halfMoveClock = 0;
    } else {
      halfMoveClock++;
    }
    if (color == 'b') fullMoveNumber++;

    turn = color == 'w' ? 'b' : 'w';
    sanHistory.add(_toSan(chosen));
    return true;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    loadFen(_history.removeLast());
    if (sanHistory.isNotEmpty) sanHistory.removeLast();
    return true;
  }

  String _toSan(ChessMove m) {
    final type = m.movedPiece[1];
    final capture = m.capturedPiece != null || m.isEnPassant;
    if (m.isCastleKingSide) return 'O-O';
    if (m.isCastleQueenSide) return 'O-O-O';
    final pieceLetter = type == 'P' ? '' : type;
    final fromFile = type == 'P' && capture ? squareName(m.from)[0] : '';
    final captureMark = capture ? 'x' : '';
    final promo = m.promotion != null ? '=${m.promotion}' : '';
    return '$pieceLetter$fromFile$captureMark${squareName(m.to)}$promo';
  }

  ChessEngine clone() {
    final c = ChessEngine();
    c.loadFen(toFen());
    return c;
  }
}
