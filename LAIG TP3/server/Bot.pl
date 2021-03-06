:- use_module(library(random)).

% Calculate the value of a board to a given player
% value( + Board, + Player, + Enemy, - Value):-
value(Board, Player, Enemy, Value):-
    countPlayerPieces(Player, Board, NumPieces),
    countEnemiesPieces(Enemy, Board, NumPiecesE),
    
    Player = [Color|_],
    Enemy = [ColorEnemy|_],
    countStarvingAdaptoids(ColorEnemy, Board, StarvingE),
    countStarvingAdaptoids(Color, Board, Starving),
    
    countEndangeredAdaptoids(Board, Player, Enemy, Num, NumE),
	
    Value is 2*NumPieces - 2*NumPiecesE + StarvingE - Starving + NumE - Num, !.


countStarvingAdaptoids(Color, Board, Num) :-
	findall([R,C], getPiece(R,C,Board,[Color|_]), Pieces),
	findStarvingAdptoids(Pieces, Board, Num).

findStarvingAdptoids([], _, 0).
findStarvingAdptoids([[R,C]|Ps], Board, N1) :-
	findall([NR,NC], isFreeSpace(R,C,NR,NC,Board), FreeSpacesList),
	length(FreeSpacesList, NumFreeSpaces),
	getNumExtremetiesOfAPiece(R,C,Board,Extremeties),
	isAdaptoidHungry(Extremeties, NumFreeSpaces, Flag),
	findStarvingAdptoids(Ps, Board, N),
    N1 is N + Flag.
    
isAdaptoidHungry(Extremeties, NumFreeSpaces, 1) :-
	Extremeties > NumFreeSpaces.
isAdaptoidHungry(Extremeties, NumFreeSpaces, 0) :-
	Extremeties =< NumFreeSpaces.
    
countPlayerPieces(Player, Board, NumPieces):-
    Player = [Color, Adaptoids, Legs, Pincers, Score],
    findall([L,P], getPiece(_,_,Board,[Color,L,P]), Pieces),
    countPiecesOnBoard(Pieces, NumPiecesOnBoard),
    NumPieces is Adaptoids + Legs + Pincers + Score + NumPiecesOnBoard .

countPiecesOnBoard([], 0).    
countPiecesOnBoard([[L,P]|Pieces], Num):-
    countPiecesOnBoard(Pieces, N1),
	avoidEmptyAdaptoids(L, P, Factor),
	Num is 1 + L + P - abs(L-P) + N1 + Factor.
	
avoidEmptyAdaptoids(0, 0, -1).
avoidEmptyAdaptoids(_, _, 0).

countEnemiesPieces(Player, Board, NumPieces):-
    Player = [Color, Adaptoids, Legs, Pincers, Score],
    findall([L,P], getPiece(_,_,Board,[Color,L,P]), Pieces),
    countEnemiesOnBoard(Pieces, NumPiecesOnBoard),
    NumPieces is Adaptoids + Legs + Pincers + Score + NumPiecesOnBoard .

countEnemiesOnBoard([], 0).    
countEnemiesOnBoard([_|Pieces], Num):-
    countEnemiesOnBoard(Pieces, N1),
	Num is 2 + N1.

% Count the number of pieces in danger of capture of:
% player (Num);
% enemy(NumE) 
% countEndangeredAdaptoids( + Board, + Player, + Enemy, - Num, - NumE)
countEndangeredAdaptoids(Board, Player, Enemy, Num, NumE):-
    Player = [Color | _],
    Enemy = [ColorEnemy | _],
    findall([R,C], getPiece(R,C,Board,[Color|_]), Pieces),
    findall([R,C], getPiece(R,C,Board,[ColorEnemy|_]), PiecesEnemy),
    countEndangeredAdaptoidsAux(Color, Board, Pieces, PiecesEnemy, NumE),
    countEndangeredAdaptoidsAux(ColorEnemy, Board, PiecesEnemy, Pieces, Num).

% Count the number of atacks from enemy's pieces to the player's
% countEndangeredAdaptoidsAux(+Color, + Board, + Pieces, + PiecesEnemy, - Num)
countEndangeredAdaptoidsAux(_, _, _, [], 0).    
countEndangeredAdaptoidsAux(Color, Board, Pieces, [Enemy | PiecesEnemy], Num):-
    pieceIsInDanger(Color, Board, Pieces, Enemy),
    countEndangeredAdaptoidsAux(Color, Board, Pieces, PiecesEnemy, N2),
    Num is 1 + N2.
countEndangeredAdaptoidsAux(Color, Board, Pieces, [_ | PiecesEnemy], Num):-
    countEndangeredAdaptoidsAux(Color, Board, Pieces, PiecesEnemy, Num).
   
% Count the number of atacks from an enemy's piece to the player's
% pieceIsInDanger('Color, + Board, + Pieces, + Enemy, - Num)   
pieceIsInDanger(Color, Board, [Piece|Pieces], Enemy):-
    Piece = [RowFrom, ColFrom],
    Enemy = [RowTo, ColTo],
	getPiece(RowFrom, ColFrom, Board, PieceFrom),
	getPiece(RowTo, ColTo, Board, PieceTo),
	PieceFrom = [_,Legs,PincersFrom], PieceTo = [_,_,PincersTo], 
	thereIsPath([RowFrom,ColFrom], [RowTo,ColTo], Legs, Board),
	(PincersFrom > PincersTo;
	PincersFrom =< PincersTo,
    pieceIsInDanger(Color, Board, Pieces, Enemy)).
   
%For testing only  
testValue(Value):-
    assert(player(w, 12, 12, 12, 0)), 
    assert(player(b, 12, 12, 12, 0)),
    
    boardToTestEndGame(Board),
    Player1 = [w, 12, 12, 12, 0], 
    Player2 = [b, 12, 12, 12, 0],
    
    countPlayerPieces(Player1, Board, NumPieces1),
    write('Number of white pieces '), write(NumPieces1), nl,
    countPlayerPieces(Player2, Board, NumPieces2),
    write('Number of black pieces '), write(NumPieces2), nl,
    
    countStarvingAdaptoids(w, Board, S1),
    write('Number of starving white '), write(S1), nl,
    countStarvingAdaptoids(b, Board, S2),
    write('Number of starving black '), write(S2), nl,
    
    countEndangeredAdaptoids(Board, Player1, Player2, Num, NumE),
    write('Number of endagered white '), write(Num), nl,
    write('Number of endagered black '), write(NumE), nl,

    value(Board, Player1, Player2, Value).

% valid_moves(+Board, +Player, -ListOfMoves). 
% Move = [RFrom, CFrom, RTo, CTo].
valid_moves(Board, [Color|_], ListOfMoves) :-
	findall([R,C], getPiece(R,C,Board,[Color|_]), Pieces),
	valid_moves_aux(Pieces, Board, ListOfMoves2),
	sort(ListOfMoves2, ListOfMoves).
	
valid_moves_aux([], _, []).
valid_moves_aux([[RFrom,CFrom]|Ps], Board, ListOfMoves) :-
	getPiece(RFrom, CFrom, Board, [_, Legs, _]),
	findall([RFrom, CFrom, RTo, CTo], 
	thereIsPath([RFrom, CFrom], [RTo, CTo], Legs, Board), L1), 
	valid_moves_aux(Ps, Board, L2),
	append(L1, L2, ListOfMoves). 

% valid_moves_createAdaptoid(+ Board, + Player, - ListOfMoves)	
% Move = [Row, Col]
valid_moves_createAdaptoid(Board, Player, ListOfMoves) :-
	findall([R, C], createAdaptoidValid(R, C, Board, Player), ListOfMoves2),
	sort(ListOfMoves2, ListOfMoves).
	
createAdaptoidValid(Row, Column, Board, [Color, Adaptoids|_]) :-
	Adaptoids >= 1,
	getPiece(Row, Column, Board, Piece),
    Piece = empty, 
	neighborValid(Row, Column, _, _, Color, Board).

% valid_moves_addLeg( + Board, + Player, - ListOfMoves)
% Move = [Row, Col]
valid_moves_addLeg(Board, Player, ListOfMoves) :-
	findall([R, C], addLegValid(R, C, Board, Player), ListOfMoves2),
	sort(ListOfMoves2, ListOfMoves).
	
addLegValid(Row, Column, Board, [Color, _, Legs |_]) :-
	Legs >= 1,
	getPiece(Row,Column,Board, Piece),
	Piece = [Color, Legs2, Pincers],
	Total is Legs2 + Pincers + 1,
	Total =< 6.
	
% valid_moves_addPincer( + Board, + Player, - ListOfMoves)
% Move = [Row, Col]
valid_moves_addPincer(Board, Player, ListOfMoves) :-
	findall([R, C], addPincerValid(R, C, Board, Player), ListOfMoves2),
	sort(ListOfMoves2, ListOfMoves).

addPincerValid(Row, Column, Board, [Color, _, _, Pincers |_]) :-
	Pincers >= 1,
	getPiece(Row,Column,Board, Piece),
	Piece = [Color, Legs, Pincers2],
	Total is Legs + Pincers2 + 1,
	Total =< 6.

botMoveAndCapture(Color, BoardIn, BoardOut, PlayerFromIn, PlayerFromOut, PlayerToIn, PlayerToOut, RFrom, CFrom, RTo, CTo):-
    findBestFirstMove(BoardIn, PlayerFromIn, PlayerToIn, RFrom, CFrom, RTo, CTo),
	moveAndCapture(Color, RFrom, CFrom, RTo, CTo, BoardIn, BoardOut, PlayerFromIn, PlayerFromOut, PlayerToIn, PlayerToOut).
	
% Finds the best move possible in the Player's first move in a turn
% Uma jogada e definida como: [RFrom, CFrom, RTo, CTo].
% findBestFirstMove( + Board, + Player, + Enemy, - RFrom, - CFrom, - RTo, - CTo) 
findBestFirstMove(Board, Player, Enemy, RFrom, CFrom, RTo, CTo) :-
	valid_moves(Board, Player, ListOfMoves),
	findBestFirstMoveAux(Board, Player, Enemy, ListOfMoves, -10000, 1, 1, MaxValue, _),
	findBestFirstMoveAux2(Board, Player, Enemy, ListOfMoves, MaxValue, BestMoves),
	length(BestMoves, N), 
	Limit is N + 1,
	random(1, Limit, IndexOfBestMove),
	nth1(IndexOfBestMove, BestMoves, [RFrom, CFrom, RTo, CTo]).

findBestFirstMoveAux(_, _, _, [], CurrMax, CurrIndex, _, CurrMax, CurrIndex).
findBestFirstMoveAux(Board, Player, Enemy, [Move|Ms], CurrMax, CurrIndexMax, CurrIndex, MaxValue, IndexOfBestMove) :-
	Player = [Color|_],
	Move = [RFrom, CFrom, RTo, CTo],
	moveAndCapture(Color, RFrom, CFrom, RTo, CTo, Board, BoardOut, Player, _, Enemy, _),
	value(BoardOut, Player, Enemy, Value),
	NewIndex is CurrIndex + 1,
	(Value > CurrMax,
	findBestFirstMoveAux(Board, Player, Enemy, Ms, Value, CurrIndex, NewIndex, MaxValue, IndexOfBestMove);
	Value =< CurrMax,
	findBestFirstMoveAux(Board, Player, Enemy, Ms, CurrMax, CurrIndexMax, NewIndex, MaxValue, IndexOfBestMove)).

findBestFirstMoveAux2(_, _, _, [], _, []).
findBestFirstMoveAux2(Board, Player, Enemy, [Move|Ms], MaxValue, BestMoves) :-
	Player = [Color|_],
	Move = [RFrom, CFrom, RTo, CTo],
	moveAndCapture(Color, RFrom, CFrom, RTo, CTo, Board, BoardOut, Player, _, Enemy, _),
	value(BoardOut, Player, Enemy, Value), 
	(Value =:= MaxValue,
	findBestFirstMoveAux2(Board, Player, Enemy, Ms, MaxValue, BestMovesAux),
	LM = [Move], append(LM, BestMovesAux, BestMoves);
	Value < MaxValue, 
	findBestFirstMoveAux2(Board, Player, Enemy, Ms, MaxValue, BestMoves)).

test_findBestFirstMove :-
    assert(player(w, 12, 12, 12, 0)), 
    assert(player(b, 12, 12, 12, 0)),
    
    boardToTestCaptureHungryAdaptoids(Board), printBoard(Board), 
    Player1 = [w, 12, 12, 12, 0], 
    Player2 = [b, 12, 12, 12, 0],
  
    findBestFirstMove(Board, Player1, Player2, RFrom, CFrom, RTo, CTo),  
	
	write(RFrom), write('-'), write(CFrom), 
	write(' -> '), 
	write(RTo), write('-'), write(CTo), nl, nl.
	
botCreateOrUpdate(Color, BoardIn, BoardOut, PlayerIn, PlayerOut, Enemy, Type, Row, Col):-
    bestMoveCreateOrUpdate(BoardIn, PlayerIn, Enemy, BestMove),
    BestMove = [Type, Row, Col],
    botCreateOrUpdateByType(Type, Row, Col, Color, BoardIn, BoardOut, PlayerIn, PlayerOut).
    
botCreateOrUpdateByType(0, Row, Col, Color, BoardIn, BoardOut, PlayerIn, PlayerOut):-
    createAdaptoid(Color, PlayerIn, Row, Col, BoardIn, BoardOut, PlayerOut).
botCreateOrUpdateByType(1, Row, Col, Color, BoardIn, BoardOut, PlayerIn, PlayerOut):-
    addLeg(Color, PlayerIn, Row, Col, BoardIn, BoardOut, PlayerOut).
botCreateOrUpdateByType(2, Row, Col, Color, BoardIn, BoardOut, PlayerIn, PlayerOut):-
    addPincer(Color, PlayerIn, Row, Col, BoardIn, BoardOut, PlayerOut).

%Choses the best move to be done in this part of the game returns BestMove = [Type,Row,Column].
%bestMoveCreateOrUpdate(+Board, +Player, -BestMove   
bestMoveCreateOrUpdate(Board, Player, Enemy, BestMove):-
    setof([Value, Type, R, C], valueOfCreateOrUpdate(Type, R, C, Board, Player, Enemy, Value), Values),
    last(Values, [MaxValue| _]),
    getCreateOrUpdateMaxValue(MaxValue, Values , BestMoves),
    random_member(BestMove, BestMoves).  
 
%Returns list of enemy player status
getEnemy(Color, Enemy):-
    getColorOfEnemy(Color, ColorEnemy),
    player(ColorEnemy, Adaptoids, Legs, Pincers, Score),
    Enemy = [ColorEnemy, Adaptoids, Legs, Pincers, Score].

%Given the coordinates the board and the player returns the value of the move of type Type
%valueOfCreation(+Type, +R, +C, +BoardIn, +Player, -Value)    
valueOfCreateOrUpdate(0, R, C, BoardIn, Player, Enemy, Value):-
    Player = [Color | _],
    createAdaptoidValid(R, C, BoardIn, Player), 
    createAdaptoid(Color, Player, R, C, BoardIn, BoardOut, PlayerOut),
    value(BoardOut, PlayerOut, Enemy, Value).
	
valueOfCreateOrUpdate(1, R, C, BoardIn, Player, Enemy, Value):-
    Player = [Color | _],
    addLegValid(R, C, BoardIn, Player), 
    addLeg(Color, Player, R, C, BoardIn, BoardOut, PlayerOut),
    value(BoardOut, PlayerOut, Enemy, Value).
    
valueOfCreateOrUpdate(2, R, C, BoardIn, Player, Enemy, Value):-
    Player = [Color | _],
    addPincerValid(R, C, BoardIn, Player), 
    addPincer(Color, Player, R, C, BoardIn, BoardOut, PlayerOut),
    value(BoardOut, PlayerOut, Enemy, Value).

%Get the list of best moves
%getCreateOrUpdateMaxValue(+MaxValue, +Moves , -BestMoves)
getCreateOrUpdateMaxValue(_, [] , []).    
getCreateOrUpdateMaxValue(MaxValue, [M|Moves] , [Move|BestMoves]):-
    M = [Value|Move],
    Value =:= MaxValue,
    getCreateOrUpdateMaxValue(MaxValue, Moves , BestMoves).
getCreateOrUpdateMaxValue(MaxValue, [M|Moves] , BestMoves):-
    M = [Value|_],
    Value =\= MaxValue,
    getCreateOrUpdateMaxValue(MaxValue, Moves , BestMoves).

%choses the best among the best of each type of move returns BestMove=[Type,Row,Column]
%chooseBestMoveCreateOrUpdate(+BestCreation,+BestAddLeg,+BestAddPincer,-BestMove)	
chooseBestMoveCreateOrUpdate([ValCreation,R,C],[ValAddLeg | _],[ValAddPincer | _],['creation',R,C]):-
    ValCreation >= ValAddLeg, ValCreation >= ValAddPincer, ! .
chooseBestMoveCreateOrUpdate([ValCreation |_],[ValAddLeg,R,C],[ValAddPincer | _],['addLeg',R,C]):-
    ValAddLeg >= ValCreation, ValAddLeg >= ValAddPincer, ! .
chooseBestMoveCreateOrUpdate(_,_,[_,R,C],['addPincer',R,C]).

%Generates a random possible first move
%randomFirstMove(+ Board, + Player, - Move) 
randomFirstMove(Board, Player, Move) :-
	valid_moves(Board, Player, ListOfMoves),
	length(ListOfMoves, NumMoves),
	MaxLimit is NumMoves + 1,
	random(1, MaxLimit, IndexOfMove),
	nth1(IndexOfMove, ListOfMoves, Move).
	
test_randomFirstMove :-
	assert(player(w, 12, 12, 12, 0)), 
    assert(player(b, 12, 12, 12, 0)),
    
    boardToTestValidMoves(Board),
    Player = [w, 12, 12, 12, 0],
    randomFirstMove(Board, Player, Move),
	print(Move), nl.
	
%Generates a random possible move
%randomMoveCreateOrUpdate(+Board, +Player,-Move)
randomMoveCreateOrUpdate(Board, Player,Move):-
    random(1, 4, Type),
    randomMoveCreateOrUpdateAux(Type, Board, Player,Move).

%Generates a random possible move according to type given (Type->action: 1->creation 2->addLeg 3->addPincer) if not possible tries another type of move
%randomMoveCreateOrUpdateAux(+Type, +Board, +Player,-Move)
randomMoveCreateOrUpdateAux(1, Board, Player,['creation',R,C]):-
    valid_moves_createAdaptoid(Board, Player, ListOfMoves),
    ListOfMoves \= [], !,
    random_member([R,C], ListOfMoves).
randomMoveCreateOrUpdateAux(1, Board, Player,Move):-    
    random(2, 4, Type),
    randomMoveCreateOrUpdateAux(Type, Board, Player,Move).
randomMoveCreateOrUpdateAux(2, Board, Player,['addLeg',R,C]):-
    valid_moves_addLeg(Board, Player, ListOfMoves),
    ListOfMoves \= [], !,
    random_member([R,C], ListOfMoves).
randomMoveCreateOrUpdateAux(3, Board, Player,['addPincer',R,C]):-
    valid_moves_addPincer(Board, Player, ListOfMoves),
    ListOfMoves \= [], !,
    random_member([R,C], ListOfMoves).
randomMoveCreateOrUpdateAux(Type, Board, Player,Move):-
    Type =\= 1,
    randomMoveCreateOrUpdateAux(1, Board, Player,Move).

%For testing purposes only
testBestMove(BestMove, Move):-
    assert(player(w, 12, 12, 12, 0)), 
    assert(player(b, 12, 12, 12, 0)),
    
    boardToTestValidMoves(Board),
    Player = [w, 12, 12, 12, 0],
    bestMoveCreateOrUpdate(Board, Player, BestMove),
    randomMoveCreateOrUpdate(Board, Player,Move).

