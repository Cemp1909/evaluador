import '../models/bloque.dart';
import '../models/clase.dart';
import '../models/evaluador_tipo.dart';
import '../models/item_referencia.dart';

const _abcItems = [
  ItemReferencia(texto: "Let's sing (commands)"),
  ItemReferencia(texto: "Let's practice the song (commands)"),
  ItemReferencia(texto: "It's time to sing (learn/practice the commands)"),
  ItemReferencia(texto: 'At count of three'),
  ItemReferencia(texto: 'Are you ready? Ready, let\'s go'),
  ItemReferencia(texto: 'Lights, camera, action'),
  ItemReferencia(texto: 'What do you see?'),
  ItemReferencia(texto: 'How do you say?'),
  ItemReferencia(texto: 'Guys, students, children'),
];

const _preescolarClases = [
  Clase(
    numero: 1,
    bloques: [
      Bloque(
        nombre: 'Songs 1',
        items: [
          ItemReferencia(texto: 'Hello song'),
          ItemReferencia(texto: 'Hello dear teacher'),
          ItemReferencia(texto: 'Good morning'),
          ItemReferencia(texto: 'Vocabulary Song'),
        ],
      ),
      Bloque(
        nombre: 'Songs 2',
        items: [
          ItemReferencia(texto: 'Hello (Super Simple)'),
          ItemReferencia(texto: 'Hello song for kids'),
          ItemReferencia(texto: 'Make a Circle'),
        ],
      ),
      Bloque(
        nombre: 'Dialogues',
        items: [
          ItemReferencia(texto: 'Pre-K 1'),
          ItemReferencia(texto: 'Kindergarten 1'),
        ],
      ),
      Bloque(
        nombre: 'Commands',
        items: [ItemReferencia(texto: 'Blue Page')],
      ),
      Bloque(nombre: 'ABC', items: _abcItems),
    ],
  ),
  Clase(
    numero: 2,
    bloques: [
      Bloque(
        nombre: 'Songs 1',
        items: [
          ItemReferencia(texto: 'The colors'),
          ItemReferencia(texto: 'Happy fruits'),
          ItemReferencia(texto: 'Alphabet song'),
          ItemReferencia(texto: 'This is the way'),
          ItemReferencia(texto: 'Baa baa black sheep'),
        ],
      ),
      Bloque(
        nombre: 'Songs 2',
        items: [
          ItemReferencia(texto: 'Point and Touch'),
          ItemReferencia(texto: 'Happy fruits'),
          ItemReferencia(texto: 'Tea cup'),
          ItemReferencia(texto: 'Baa baa black sheep'),
        ],
      ),
      Bloque(
        nombre: 'Vocabulary',
        items: [
          ItemReferencia(texto: 'Colors'),
          ItemReferencia(texto: 'Patriotic symbols'),
          ItemReferencia(texto: 'Body parts'),
          ItemReferencia(texto: 'Face'),
          ItemReferencia(texto: 'Professions'),
          ItemReferencia(texto: 'Family'),
          ItemReferencia(texto: 'Alphabet'),
          ItemReferencia(texto: 'City'),
          ItemReferencia(texto: 'Farm Animals'),
        ],
      ),
      Bloque(
        nombre: 'Information Questions',
        items: [
          ItemReferencia(texto: 'What is it?'),
          ItemReferencia(texto: 'What ___ is it?'),
          ItemReferencia(texto: 'What are they?'),
          ItemReferencia(texto: 'Who is he / she?'),
        ],
      ),
      Bloque(
        nombre: 'Dialogues',
        items: [
          ItemReferencia(texto: 'Transition 1'),
          ItemReferencia(texto: 'Pre-K 2'),
        ],
      ),
      Bloque(nombre: 'ABC', items: _abcItems),
    ],
  ),
  Clase(
    numero: 3,
    bloques: [
      Bloque(
        nombre: 'Songs',
        items: [
          ItemReferencia(texto: 'Head and shoulders'),
          ItemReferencia(texto: 'Put on your shoes'),
          ItemReferencia(texto: 'Walking in the jungle'),
        ],
      ),
      Bloque(
        nombre: 'Dialogues',
        items: [
          ItemReferencia(texto: 'Kindergarten 2'),
          ItemReferencia(texto: 'Transition 2'),
        ],
      ),
      Bloque(
        nombre: 'Commands',
        items: [ItemReferencia(texto: 'Green Page')],
      ),
      Bloque(nombre: 'ABC', items: _abcItems),
    ],
  ),
  Clase(
    numero: 4,
    bloques: [
      Bloque(
        nombre: 'Songs 1',
        items: [
          ItemReferencia(texto: 'Merry Christmas'),
          ItemReferencia(texto: 'The wheels of the bus'),
          ItemReferencia(texto: 'Twinkle little star'),
        ],
      ),
      Bloque(
        nombre: 'Songs 2',
        items: [
          ItemReferencia(texto: 'Jingle bells (rock)'),
          ItemReferencia(texto: 'The wheels of the bus'),
          ItemReferencia(texto: 'Chu chu wa'),
        ],
      ),
      Bloque(
        nombre: 'Vocabulary',
        items: [
          ItemReferencia(texto: 'Parts of the house'),
          ItemReferencia(texto: 'Kitchen'),
          ItemReferencia(texto: 'Dining room'),
          ItemReferencia(texto: 'Living room'),
          ItemReferencia(texto: 'Bedroom'),
          ItemReferencia(texto: 'Bathroom'),
          ItemReferencia(texto: 'Fruits'),
          ItemReferencia(texto: 'Numbers'),
          ItemReferencia(texto: 'Sea animals'),
        ],
      ),
      Bloque(
        nombre: 'Dialogues',
        items: [
          ItemReferencia(texto: 'Pre-K 3'),
          ItemReferencia(texto: 'Kindergarten 3'),
        ],
      ),
      Bloque(nombre: 'ABC', items: _abcItems),
    ],
  ),
  Clase(
    numero: 5,
    bloques: [
      Bloque(
        nombre: 'Songs 1',
        items: [
          ItemReferencia(texto: 'Rice pudding'),
          ItemReferencia(texto: 'Old McDonald'),
          ItemReferencia(texto: 'Bingo'),
          ItemReferencia(texto: 'Ten little number'),
        ],
      ),
      Bloque(
        nombre: 'Songs 2',
        items: [
          ItemReferencia(texto: 'Pinocchio'),
          ItemReferencia(texto: 'Old McDonald'),
          ItemReferencia(texto: 'Bingo'),
          ItemReferencia(texto: 'Ten little number'),
        ],
      ),
      Bloque(
        nombre: 'Commands',
        items: [ItemReferencia(texto: 'Pink Page')],
      ),
      Bloque(
        nombre: 'Dialogues',
        items: [
          ItemReferencia(texto: 'Transition 3'),
          ItemReferencia(texto: 'Pre-K 4'),
        ],
      ),
      Bloque(nombre: 'ABC', items: _abcItems),
    ],
  ),
  Clase(
    numero: 6,
    bloques: [
      Bloque(
        nombre: 'Songs 1',
        items: [
          ItemReferencia(texto: 'Rain rain go away'),
          ItemReferencia(texto: "If you're happy"),
          ItemReferencia(texto: 'Mary had a little lamb'),
          ItemReferencia(texto: 'My house'),
        ],
      ),
      Bloque(
        nombre: 'Songs 2',
        items: [
          ItemReferencia(texto: 'Jesus is my best friend'),
          ItemReferencia(texto: "If you're happy"),
          ItemReferencia(texto: 'Eensey spider'),
          ItemReferencia(texto: 'Are you sleeping'),
        ],
      ),
      Bloque(
        nombre: 'Vocabulary',
        items: [
          ItemReferencia(texto: 'Classroom'),
          ItemReferencia(texto: 'Geometric figures'),
          ItemReferencia(texto: 'Wild animals'),
          ItemReferencia(texto: 'Food'),
          ItemReferencia(texto: 'Vegetables'),
          ItemReferencia(texto: 'My garden'),
          ItemReferencia(texto: 'Opposite'),
          ItemReferencia(texto: 'Clothes'),
          ItemReferencia(texto: 'Mass media'),
          ItemReferencia(texto: 'Transports'),
        ],
      ),
      Bloque(nombre: 'ABC', items: _abcItems),
      Bloque(
        nombre: 'Dialogues',
        items: [
          ItemReferencia(texto: 'Kindergarten 4'),
          ItemReferencia(texto: 'Transition 4'),
        ],
      ),
    ],
  ),
];

const _primariaClases = [
  Clase(
    numero: 1,
    bloques: [
      Bloque(
        nombre: 'Grammar',
        items: [
          ItemReferencia(texto: 'a, an, the, R+R-'),
          ItemReferencia(texto: 'or, and'),
          ItemReferencia(texto: 'The date'),
          ItemReferencia(texto: 'Plurals'),
        ],
      ),
      Bloque(
        nombre: 'Questions',
        items: [
          ItemReferencia(texto: 'What is it? Is it ___?'),
          ItemReferencia(texto: 'It is ___.'),
          ItemReferencia(texto: 'Do you prefer/like ___ or ___?'),
          ItemReferencia(texto: 'I prefer/like ___.'),
          ItemReferencia(texto: 'When is your birthday?'),
        ],
      ),
    ],
  ),
  Clase(
    numero: 2,
    bloques: [
      Bloque(
        nombre: 'Grammar',
        items: [
          ItemReferencia(texto: 'Demonstrative adjectives'),
          ItemReferencia(texto: 'Prepositions of place'),
          ItemReferencia(texto: 'There is/are, some, any'),
          ItemReferencia(texto: 'Personal pronouns'),
        ],
      ),
      Bloque(
        nombre: 'Questions',
        items: [
          ItemReferencia(texto: 'What is this? What is that?'),
          ItemReferencia(texto: 'What are these? What are those?'),
          ItemReferencia(texto: 'Where is it?'),
          ItemReferencia(texto: 'Is there ___?'),
          ItemReferencia(texto: 'Are there ___?'),
          ItemReferencia(texto: 'How do you say ___?'),
        ],
      ),
    ],
  ),
  Clase(
    numero: 3,
    bloques: [
      Bloque(
        nombre: 'Songs',
        items: [
          ItemReferencia(texto: 'Iguana'),
          ItemReferencia(texto: 'Crazy witch'),
          ItemReferencia(texto: 'Jesus is my friend best'),
        ],
      ),
      Bloque(
        nombre: 'New Songs',
        items: [
          ItemReferencia(texto: 'Iguana'),
          ItemReferencia(texto: 'Little chicks'),
          ItemReferencia(texto: 'The time'),
        ],
      ),
      Bloque(
        nombre: 'Commands',
        items: [ItemReferencia(texto: 'Pink Page')],
      ),
      Bloque(nombre: 'Teaching Strategy', items: []),
    ],
  ),
  Clase(
    numero: 4,
    bloques: [
      Bloque(
        nombre: 'Grammar',
        items: [
          ItemReferencia(texto: "Can, can't"),
          ItemReferencia(texto: 'Verb to be'),
          ItemReferencia(texto: 'Possessive adjectives'),
          ItemReferencia(texto: 'The time'),
          ItemReferencia(texto: 'Verbs'),
        ],
      ),
      Bloque(
        nombre: 'Questions',
        items: [
          ItemReferencia(texto: 'Can you ___?'),
          ItemReferencia(texto: 'Whose ___ is this?'),
          ItemReferencia(texto: 'What time is it?'),
        ],
      ),
    ],
  ),
  Clase(
    numero: 5,
    bloques: [
      Bloque(
        nombre: 'Songs',
        items: [
          ItemReferencia(texto: 'Love me do'),
          ItemReferencia(texto: 'Yellow submarine'),
          ItemReferencia(texto: 'Lady hear me tonight'),
          ItemReferencia(texto: 'Magic'),
        ],
      ),
      Bloque(
        nombre: 'Commands',
        items: [ItemReferencia(texto: 'Green Pages')],
      ),
      Bloque(nombre: 'Teaching Strategy', items: []),
    ],
  ),
  Clase(
    numero: 6,
    bloques: [
      Bloque(
        nombre: 'Grammar',
        items: [
          ItemReferencia(texto: 'Progressive tense: present, past, future'),
          ItemReferencia(texto: 'Present simple rules'),
          ItemReferencia(texto: 'Have - has'),
        ],
      ),
      Bloque(nombre: 'Questions', items: []),
    ],
  ),
  Clase(
    numero: 7,
    bloques: [
      Bloque(
        nombre: 'Songs',
        items: [
          ItemReferencia(texto: "Can't stop the feeling"),
          ItemReferencia(texto: 'Unstoppable'),
          ItemReferencia(texto: 'Alone'),
          ItemReferencia(texto: 'Safe and sound'),
        ],
      ),
      Bloque(
        nombre: 'Commands',
        items: [ItemReferencia(texto: 'Orange Page')],
      ),
      Bloque(nombre: 'Teaching Strategy', items: []),
    ],
  ),
  Clase(
    numero: 8,
    bloques: [
      Bloque(
        nombre: 'Grammar',
        items: [
          ItemReferencia(texto: 'Past simple: regular and irregular verbs'),
          ItemReferencia(texto: 'Prepositions of time'),
          ItemReferencia(
            texto: 'Countables vs. uncountables (how much vs. how many)',
          ),
        ],
      ),
      Bloque(
        nombre: 'Questions',
        items: [
          ItemReferencia(texto: 'What did you do yesterday?'),
          ItemReferencia(texto: 'When do you usually study?'),
          ItemReferencia(texto: 'How much / many ___?'),
        ],
      ),
    ],
  ),
  Clase(
    numero: 9,
    bloques: [
      Bloque(
        nombre: 'Grammar',
        items: [
          ItemReferencia(texto: 'Possessive pronouns'),
          ItemReferencia(texto: 'Object pronouns'),
          ItemReferencia(texto: 'Reflexive pronouns'),
        ],
      ),
      Bloque(
        nombre: 'Questions',
        items: [
          ItemReferencia(texto: 'Who do you play with at break?'),
          ItemReferencia(texto: 'I play with them / him / her.'),
        ],
      ),
    ],
  ),
  Clase(
    numero: 10,
    bloques: [
      Bloque(
        nombre: 'Grammar',
        items: [
          ItemReferencia(texto: 'Adverbs of frequency'),
          ItemReferencia(texto: 'Do vs. Make'),
          ItemReferencia(texto: 'Future: Will vs. Going to'),
        ],
      ),
      Bloque(
        nombre: 'Questions',
        items: [
          ItemReferencia(texto: 'How often do you ___?'),
          ItemReferencia(texto: 'What do you do / make during the day?'),
          ItemReferencia(texto: 'What are you going to do this weekend?'),
          ItemReferencia(texto: 'What will you do in the future?'),
        ],
      ),
    ],
  ),
  Clase(
    numero: 11,
    bloques: [
      Bloque(
        nombre: 'Grammar',
        items: [ItemReferencia(texto: 'Comparatives and superlatives')],
      ),
      Bloque(
        nombre: 'New Grammar',
        items: [ItemReferencia(texto: 'Review')],
      ),
      Bloque(nombre: 'Teaching Strategy', items: []),
    ],
  ),
];

const evaluadoresDisponibles = [
  EvaluadorTipo(
    codigo: 'capacitacion_preescolar',
    nombre: 'Capacitación Preescolar',
    clases: _preescolarClases,
  ),
  EvaluadorTipo(
    codigo: 'capacitacion_primaria',
    nombre: 'Capacitación Primaria',
    clases: _primariaClases,
  ),
];
