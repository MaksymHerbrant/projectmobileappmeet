import 'package:flutter/material.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['uk', 'en', 'pl', 'pt', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('uk'));
  }



  static const Map<String, Map<String, String>> _localizedValues = {
    'uk': {
      // Загальні
      'app_name': 'Bondee',
      'ok': 'OK',
      'cancel': 'Скасувати',
      'save': 'Зберегти',
      'edit': 'Редагувати',
      'delete': 'Видалити',
      'back': 'Назад',
      'next': 'Далі',
      'previous': 'Назад',
      'done': 'Готово',
      'loading': 'Завантаження...',
      'error': 'Помилка',
      'success': 'Успішно',
      
      // Реєстрація та вхід
      'registration': 'Реєстрація',
      'login': 'Вхід',
      'step': 'Крок',
      'of': 'з',
      'phone_number': 'Номер телефону',
      'password': 'Пароль',
      'confirm_password': 'Підтвердіть пароль',
      'name': 'Ім\'я',
      'age': 'Вік',
      'location': 'Місце знаходження',
      'about_me': 'Про себе',
      'hobbies': 'Хобі',
      'continue': 'Продовжити',
      'enter': 'Увійти',
      'register': 'Зареєструватися',
      'forgot_password': 'Забули пароль?',
      'already_have_account': 'Вже маєте акаунт?',
      
      // Головний екран
      'for_you': 'Для вас',
      'events_nearby': 'Заходи поблизу',
      'like': 'Подобається',
      'dislike': 'Не подобається',
      'super_like': 'Супер лайк',
      
      // Профіль
      'profile': 'Профіль',
      'my_profile': 'Мій профіль',
      'edit_profile': 'Редагування профілю',
      'settings': 'Налаштування',
      'more': 'більше',
      'less': 'менше',
      'distance': 'відстань',
      'km_away': 'км від вас',
      
      // Чат
      'chats': 'Чати',
      'messages': 'Повідомлення',
      'search': 'Пошук',
      'online': 'онлайн',
      'typing': 'друкує...',
      'send': 'Надіслати',
      'new_message': 'Нове повідомлення',
      'search_contacts': 'Пошук контактів...',
      'active_contacts': 'Активні контакти',
      'create_group': 'Створити групу',
      'join_group': 'Приєднатися до групи',
      'private_group': 'Приватна група',
      'public_group': 'Публічна група',
      'group_name': 'Назва групи',
      'group_description': 'Опис групи',
      'group_members': 'учасників',

      'group_joined': 'Ви успішно приєдналися до групи',
      
      // Заходи
      'events': 'Заходи',
      'event_details': 'Деталі заходу',
      'participants': 'учасників',
      'date': 'Дата',
      'time': 'Час',
      'address': 'Адреса',
      'join': 'Приєднатися',
      'leave': 'Покинути',
      
      // Налаштування
      'language': 'Мова',
      'notifications': 'Сповіщення',
      'privacy': 'Приватність',
      'search_preferences': 'Параметри пошуку',
      'account': 'Акаунт',
      'enable_notifications': 'Увімкнути сповіщення',
      'new_matches': 'Нові збіги',
      'messages_notifications': 'Повідомлення',
      'events_nearby_notifications': 'Заходи поблизу',
      'location_access': 'Розташування',
      'dark_mode': 'Темна тема',
      'max_distance': 'Максимальна відстань',
      'age_range': 'Віковий діапазон',
      'years_old': 'років',
      'change_password': 'Змінити пароль',
      'email': 'Електронна пошта',
      'delete_account': 'Видалити акаунт',
      'language_changed': 'Мова змінена',
      'language_changed_message': 'Мова додатку змінена. Зміни застосуються після перезапуску додатку.',
      
      // Діалоги
      'confirm_delete': 'Підтвердження видалення',
      'delete_account_confirm': 'Ви впевнені, що хочете видалити свій акаунт? Ця дія незворотна.',
      'account_deleted': 'Акаунт видалено',
      'account_deleted_message': 'Ваш акаунт успішно видалено.',
      'coming_soon': 'Скоро',
      'feature_coming_soon': 'Ця функція буде доступна в наступному оновленні.',
      
      // Хобі
      'gaming': 'Геймінг',
      'board_games': 'Настільні ігри',
      'lofi_music': 'Музика Lo-Fi',
      'camping': 'Похід з наметом',
      'fantasy_books': 'Фентезі книги',
      'photography': 'Фотографія',
      'travel': 'Подорожі',
      'cooking': 'Кулінарія',
      'sport': 'Спорт',
      'reading': 'Читання',
      'music': 'Музика',
      'dancing': 'Танці',
      'drawing': 'Малювання',
      'programming': 'Програмування',
      'yoga': 'Йога',
      'running': 'Біг',
      'cycling': 'Велоспорт',
      'swimming': 'Плавання',
      
      // Валідація
      'enter_name': 'Введіть ваше ім\'я',
      'enter_location': 'Введіть місце знаходження',
      'enter_age': 'Введіть ваш вік',
      'enter_valid_age': 'Введіть коректний вік (18-100)',
      'enter_password': 'Введіть пароль',
      'passwords_not_match': 'Паролі не співпадають',
      'enter_phone': 'Введіть номер телефону',
      'max_hobbies': 'Можна вибрати максимум 8 хобі',
      'no_events_found': 'Заходи не знайдені',
      'no_hobbies_found': 'Хобі не знайдено',
      'try_different_search': 'Спробуйте інший пошуковий запит',
    },
    'en': {
      // General
      'app_name': 'Bondee',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'done': 'Done',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      
      // Registration and Login
      'registration': 'Registration',
      'login': 'Login',
      'step': 'Step',
      'of': 'of',
      'phone_number': 'Phone number',
      'password': 'Password',
      'confirm_password': 'Confirm password',
      'name': 'Name',
      'age': 'Age',
      'location': 'Location',
      'about_me': 'About me',
      'hobbies': 'Hobbies',
      'continue': 'Continue',
      'enter': 'Enter',
      'register': 'Register',
      'forgot_password': 'Forgot password?',
      'already_have_account': 'Already have an account?',
      
      // Main screen
      'for_you': 'For you',
      'events_nearby': 'Events nearby',
      'like': 'Like',
      'dislike': 'Dislike',
      'super_like': 'Super like',
      
      // Profile
      'profile': 'Profile',
      'my_profile': 'My Profile',
      'edit_profile': 'Edit Profile',
      'settings': 'Settings',
      'more': 'more',
      'less': 'less',
      
      // Chat
      'chats': 'Chats',
      'messages': 'Messages',
      'search': 'Search',
      'online': 'online',
      'typing': 'typing...',
      'send': 'Send',
      'new_message': 'New message',
      
      // Events
      'events': 'Events',
      'event_details': 'Event Details',
      'participants': 'participants',
      'date': 'Date',
      'time': 'Time',
      'address': 'Address',
      'join': 'Join',
      'leave': 'Leave',
      
      // Settings
      'language': 'Language',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'search_preferences': 'Search Preferences',
      'account': 'Account',
      'enable_notifications': 'Enable notifications',
      'new_matches': 'New matches',
      'messages_notifications': 'Messages',
      'events_nearby_notifications': 'Events nearby',
      'location_access': 'Location',
      'dark_mode': 'Dark mode',
      'max_distance': 'Maximum distance',
      'age_range': 'Age range',
      'years_old': 'years old',
      'change_password': 'Change password',
      'email': 'Email',
      'delete_account': 'Delete account',
      'language_changed': 'Language changed',
      'language_changed_message': 'App language has been changed. Changes will apply after app restart.',
      
      // Dialogs
      'confirm_delete': 'Confirm deletion',
      'delete_account_confirm': 'Are you sure you want to delete your account? This action is irreversible.',
      'account_deleted': 'Account deleted',
      'account_deleted_message': 'Your account has been successfully deleted.',
      'coming_soon': 'Coming soon',
      'feature_coming_soon': 'This feature will be available in the next update.',
      
      // Hobbies
      'gaming': 'Gaming',
      'board_games': 'Board games',
      'lofi_music': 'Lo-Fi Music',
      'camping': 'Camping',
      'fantasy_books': 'Fantasy books',
      'photography': 'Photography',
      'travel': 'Travel',
      'cooking': 'Cooking',
      'sport': 'Sport',
      'reading': 'Reading',
      'music': 'Music',
      'dancing': 'Dancing',
      'drawing': 'Drawing',
      'programming': 'Programming',
      'yoga': 'Yoga',
      'running': 'Running',
      'cycling': 'Cycling',
      'swimming': 'Swimming',
      
      // Validation
      'enter_name': 'Enter your name',
      'enter_location': 'Enter location',
      'enter_age': 'Enter your age',
      'enter_valid_age': 'Enter valid age (18-100)',
      'enter_password': 'Enter password',
      'passwords_not_match': 'Passwords do not match',
      'enter_phone': 'Enter phone number',
      'max_hobbies': 'You can select up to 8 hobbies',
      'no_events_found': 'No events found',
      'no_hobbies_found': 'No hobbies found',
      'try_different_search': 'Try a different search query',
    },
    'pl': {
      // Ogólne
      'app_name': 'Bondee',
      'ok': 'OK',
      'cancel': 'Anuluj',
      'save': 'Zapisz',
      'edit': 'Edytuj',
      'delete': 'Usuń',
      'back': 'Wstecz',
      'next': 'Dalej',
      'previous': 'Poprzedni',
      'done': 'Gotowe',
      'loading': 'Ładowanie...',
      'error': 'Błąd',
      'success': 'Sukces',
      
      // Rejestracja i logowanie
      'registration': 'Rejestracja',
      'login': 'Logowanie',
      'step': 'Krok',
      'of': 'z',
      'phone_number': 'Numer telefonu',
      'password': 'Hasło',
      'confirm_password': 'Potwierdź hasło',
      'name': 'Imię',
      'age': 'Wiek',
      'location': 'Lokalizacja',
      'about_me': 'O mnie',
      'hobbies': 'Hobby',
      'continue': 'Kontynuuj',
      'enter': 'Wejdź',
      'register': 'Zarejestruj się',
      'forgot_password': 'Zapomniałeś hasła?',
      'already_have_account': 'Masz już konto?',
      
      // Ekran główny
      'for_you': 'Dla Ciebie',
      'events_nearby': 'Wydarzenia w pobliżu',
      'like': 'Lubię',
      'dislike': 'Nie lubię',
      'super_like': 'Super lubię',
      
      // Profil
      'profile': 'Profil',
      'my_profile': 'Mój profil',
      'edit_profile': 'Edytuj profil',
      'settings': 'Ustawienia',
      'more': 'więcej',
      'less': 'mniej',
      
      // Czat
      'chats': 'Czaty',
      'messages': 'Wiadomości',
      'search': 'Szukaj',
      'online': 'online',
      'typing': 'pisze...',
      'send': 'Wyślij',
      'new_message': 'Nowa wiadomość',
      
      // Wydarzenia
      'events': 'Wydarzenia',
      'event_details': 'Szczegóły wydarzenia',
      'participants': 'uczestników',
      'date': 'Data',
      'time': 'Czas',
      'address': 'Adres',
      'join': 'Dołącz',
      'leave': 'Opuść',
      
      // Ustawienia
      'language': 'Język',
      'notifications': 'Powiadomienia',
      'privacy': 'Prywatność',
      'search_preferences': 'Preferencje wyszukiwania',
      'account': 'Konto',
      'enable_notifications': 'Włącz powiadomienia',
      'new_matches': 'Nowe dopasowania',
      'messages_notifications': 'Wiadomości',
      'events_nearby_notifications': 'Wydarzenia w pobliżu',
      'location_access': 'Lokalizacja',
      'dark_mode': 'Tryb ciemny',
      'max_distance': 'Maksymalna odległość',
      'age_range': 'Zakres wieku',
      'years_old': 'lat',
      'change_password': 'Zmień hasło',
      'email': 'Email',
      'delete_account': 'Usuń konto',
      'language_changed': 'Język zmieniony',
      'language_changed_message': 'Język aplikacji został zmieniony. Zmiany będą widoczne po ponownym uruchomieniu aplikacji.',
      
      // Dialogi
      'confirm_delete': 'Potwierdź usunięcie',
      'delete_account_confirm': 'Czy na pewno chcesz usunąć swoje konto? Ta akcja jest nieodwracalna.',
      'account_deleted': 'Konto usunięte',
      'account_deleted_message': 'Twoje konto zostało pomyślnie usunięte.',
      'coming_soon': 'Wkrótce',
      'feature_coming_soon': 'Ta funkcja będzie dostępna w następnej aktualizacji.',
      
      // Hobby
      'gaming': 'Gry',
      'board_games': 'Gry planszowe',
      'lofi_music': 'Muzyka Lo-Fi',
      'camping': 'Kemping',
      'fantasy_books': 'Książki fantasy',
      'photography': 'Fotografia',
      'travel': 'Podróże',
      'cooking': 'Gotowanie',
      'sport': 'Sport',
      'reading': 'Czytanie',
      'music': 'Muzyka',
      'dancing': 'Taniec',
      'drawing': 'Rysowanie',
      'programming': 'Programowanie',
      'yoga': 'Joga',
      'running': 'Bieganie',
      'cycling': 'Kolarstwo',
      'swimming': 'Pływanie',
      
      // Walidacja
      'enter_name': 'Wprowadź swoje imię',
      'enter_location': 'Wprowadź lokalizację',
      'enter_age': 'Wprowadź swój wiek',
      'enter_valid_age': 'Wprowadź prawidłowy wiek (18-100)',
      'enter_password': 'Wprowadź hasło',
      'passwords_not_match': 'Hasła nie pasują',
      'enter_phone': 'Wprowadź numer telefonu',
      'max_hobbies': 'Możesz wybrać maksymalnie 8 hobby',
      'no_events_found': 'Nie znaleziono wydarzeń',
      'no_hobbies_found': 'Nie znaleziono hobby',
      'try_different_search': 'Spróbuj inne zapytanie wyszukiwania',
    },
    'pt': {
      // Geral
      'app_name': 'Bondee',
      'ok': 'OK',
      'cancel': 'Cancelar',
      'save': 'Salvar',
      'edit': 'Editar',
      'delete': 'Excluir',
      'back': 'Voltar',
      'next': 'Próximo',
      'previous': 'Anterior',
      'done': 'Concluído',
      'loading': 'Carregando...',
      'error': 'Erro',
      'success': 'Sucesso',
      
      // Registro e login
      'registration': 'Registro',
      'login': 'Entrar',
      'step': 'Passo',
      'of': 'de',
      'phone_number': 'Número de telefone',
      'password': 'Senha',
      'confirm_password': 'Confirmar senha',
      'name': 'Nome',
      'age': 'Idade',
      'location': 'Localização',
      'about_me': 'Sobre mim',
      'hobbies': 'Hobbies',
      'continue': 'Continuar',
      'enter': 'Entrar',
      'register': 'Registrar',
      'forgot_password': 'Esqueceu a senha?',
      'already_have_account': 'Já tem uma conta?',
      
      // Tela principal
      'for_you': 'Para você',
      'events_nearby': 'Eventos próximos',
      'like': 'Curtir',
      'dislike': 'Não curtir',
      'super_like': 'Super curtir',
      
      // Perfil
      'profile': 'Perfil',
      'my_profile': 'Meu Perfil',
      'edit_profile': 'Editar Perfil',
      'settings': 'Configurações',
      'more': 'mais',
      'less': 'menos',
      
      // Chat
      'chats': 'Chats',
      'messages': 'Mensagens',
      'search': 'Pesquisar',
      'online': 'online',
      'typing': 'digitando...',
      'send': 'Enviar',
      'new_message': 'Nova mensagem',
      
      // Eventos
      'events': 'Eventos',
      'event_details': 'Detalhes do Evento',
      'participants': 'participantes',
      'date': 'Data',
      'time': 'Hora',
      'address': 'Endereço',
      'join': 'Participar',
      'leave': 'Sair',
      
      // Configurações
      'language': 'Idioma',
      'notifications': 'Notificações',
      'privacy': 'Privacidade',
      'search_preferences': 'Preferências de Busca',
      'account': 'Conta',
      'enable_notifications': 'Ativar notificações',
      'new_matches': 'Novos matches',
      'messages_notifications': 'Mensagens',
      'events_nearby_notifications': 'Eventos próximos',
      'location_access': 'Localização',
      'dark_mode': 'Modo escuro',
      'max_distance': 'Distância máxima',
      'age_range': 'Faixa etária',
      'years_old': 'anos',
      'change_password': 'Alterar senha',
      'email': 'Email',
      'delete_account': 'Excluir conta',
      'language_changed': 'Idioma alterado',
      'language_changed_message': 'O idioma do aplicativo foi alterado. As alterações serão aplicadas após reiniciar o aplicativo.',
      
      // Diálogos
      'confirm_delete': 'Confirmar exclusão',
      'delete_account_confirm': 'Tem certeza de que deseja excluir sua conta? Esta ação é irreversível.',
      'account_deleted': 'Conta excluída',
      'account_deleted_message': 'Sua conta foi excluída com sucesso.',
      'coming_soon': 'Em breve',
      'feature_coming_soon': 'Este recurso estará disponível na próxima atualização.',
      
      // Hobbies
      'gaming': 'Jogos',
      'board_games': 'Jogos de tabuleiro',
      'lofi_music': 'Música Lo-Fi',
      'camping': 'Acampamento',
      'fantasy_books': 'Livros de fantasia',
      'photography': 'Fotografia',
      'travel': 'Viagem',
      'cooking': 'Culinária',
      'sport': 'Esporte',
      'reading': 'Leitura',
      'music': 'Música',
      'dancing': 'Dança',
      'drawing': 'Desenho',
      'programming': 'Programação',
      'yoga': 'Ioga',
      'running': 'Corrida',
      'cycling': 'Ciclismo',
      'swimming': 'Natação',
      
      // Validação
      'enter_name': 'Digite seu nome',
      'enter_location': 'Digite a localização',
      'enter_age': 'Digite sua idade',
      'enter_valid_age': 'Digite uma idade válida (18-100)',
      'enter_password': 'Digite a senha',
      'passwords_not_match': 'As senhas não coincidem',
      'enter_phone': 'Digite o número de telefone',
      'max_hobbies': 'Você pode selecionar até 8 hobbies',
      'no_events_found': 'Nenhum evento encontrado',
      'no_hobbies_found': 'Nenhum hobby encontrado',
      'try_different_search': 'Tente uma consulta de pesquisa diferente',
    },
    'es': {
      // General
      'app_name': 'Bondee',
      'ok': 'OK',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'edit': 'Editar',
      'delete': 'Eliminar',
      'back': 'Atrás',
      'next': 'Siguiente',
      'previous': 'Anterior',
      'done': 'Hecho',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      
      // Registro y login
      'registration': 'Registro',
      'login': 'Iniciar sesión',
      'step': 'Paso',
      'of': 'de',
      'phone_number': 'Número de teléfono',
      'password': 'Contraseña',
      'confirm_password': 'Confirmar contraseña',
      'name': 'Nombre',
      'age': 'Edad',
      'location': 'Ubicación',
      'about_me': 'Sobre mí',
      'hobbies': 'Pasatiempos',
      'continue': 'Continuar',
      'enter': 'Entrar',
      'register': 'Registrarse',
      'forgot_password': '¿Olvidaste tu contraseña?',
      'already_have_account': '¿Ya tienes una cuenta?',
      
      // Pantalla principal
      'for_you': 'Para ti',
      'events_nearby': 'Eventos cercanos',
      'like': 'Me gusta',
      'dislike': 'No me gusta',
      'super_like': 'Super me gusta',
      
      // Perfil
      'profile': 'Perfil',
      'my_profile': 'Mi Perfil',
      'edit_profile': 'Editar Perfil',
      'settings': 'Configuración',
      'more': 'más',
      'less': 'menos',
      
      // Chat
      'chats': 'Chats',
      'messages': 'Mensajes',
      'search': 'Buscar',
      'online': 'en línea',
      'typing': 'escribiendo...',
      'send': 'Enviar',
      'new_message': 'Nuevo mensaje',
      
      // Eventos
      'events': 'Eventos',
      'event_details': 'Detalles del Evento',
      'participants': 'participantes',
      'date': 'Fecha',
      'time': 'Hora',
      'address': 'Dirección',
      'join': 'Unirse',
      'leave': 'Salir',
      
      // Configuración
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'privacy': 'Privacidad',
      'search_preferences': 'Preferencias de Búsqueda',
      'account': 'Cuenta',
      'enable_notifications': 'Activar notificaciones',
      'new_matches': 'Nuevos matches',
      'messages_notifications': 'Mensajes',
      'events_nearby_notifications': 'Eventos cercanos',
      'location_access': 'Ubicación',
      'dark_mode': 'Modo oscuro',
      'max_distance': 'Distancia máxima',
      'age_range': 'Rango de edad',
      'years_old': 'años',
      'change_password': 'Cambiar contraseña',
      'email': 'Email',
      'delete_account': 'Eliminar cuenta',
      'language_changed': 'Idioma cambiado',
      'language_changed_message': 'El idioma de la aplicación ha sido cambiado. Los cambios se aplicarán después de reiniciar la aplicación.',
      
      // Diálogos
      'confirm_delete': 'Confirmar eliminación',
      'delete_account_confirm': '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción es irreversible.',
      'account_deleted': 'Cuenta eliminada',
      'account_deleted_message': 'Tu cuenta ha sido eliminada exitosamente.',
      'coming_soon': 'Próximamente',
      'feature_coming_soon': 'Esta función estará disponible en la próxima actualización.',
      
      // Pasatiempos
      'gaming': 'Videojuegos',
      'board_games': 'Juegos de mesa',
      'lofi_music': 'Música Lo-Fi',
      'camping': 'Camping',
      'fantasy_books': 'Libros de fantasía',
      'photography': 'Fotografía',
      'travel': 'Viajes',
      'cooking': 'Cocina',
      'sport': 'Deporte',
      'reading': 'Lectura',
      'music': 'Música',
      'dancing': 'Baile',
      'drawing': 'Dibujo',
      'programming': 'Programación',
      'yoga': 'Yoga',
      'running': 'Correr',
      'cycling': 'Ciclismo',
      'swimming': 'Natación',
      
      // Validación
      'enter_name': 'Ingresa tu nombre',
      'enter_location': 'Ingresa la ubicación',
      'enter_age': 'Ingresa tu edad',
      'enter_valid_age': 'Ingresa una edad válida (18-100)',
      'enter_password': 'Ingresa la contraseña',
      'passwords_not_match': 'Las contraseñas no coinciden',
      'enter_phone': 'Ingresa el número de teléfono',
      'max_hobbies': 'Puedes seleccionar hasta 8 pasatiempos',
      'no_events_found': 'No se encontraron eventos',
      'no_hobbies_found': 'No se encontraron pasatiempos',
      'try_different_search': 'Intenta una consulta de búsqueda diferente',
    },
  };

  String get(String key) {
    final languageCode = locale.languageCode;
    final translations = _localizedValues[languageCode] ?? _localizedValues['uk']!;
    return translations[key] ?? key;
  }

  static List<Locale> get supportedLocales {
    return [
      const Locale('uk'),
      const Locale('en'),
      const Locale('pl'),
      const Locale('pt'),
      const Locale('es'),
    ];
  }
} 