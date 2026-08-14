import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/auth_controller.dart';
import '../../data/countries.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/country_picker.dart';
import '../../widgets/JaBa_mark.dart';
import 'signup_screen.dart';

/// Écran de connexion : deux parcours au choix — téléphone + code SMS
/// (section 5.1 du cahier des charges) ou e-mail + mot de passe.
///
/// Aucun compte n'est pré-enregistré : la création de compte est mise en
/// avant sur les deux onglets, et le compte créé sert ensuite à se
/// reconnecter normalement.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Method { phone, email }

class _LoginScreenState extends State<LoginScreen> {
  _Method _method = _Method.phone;

  final _phoneKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Country _country = Countries.senegal;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMethod(_Method method) {
    if (_method == method) return;
    FocusScope.of(context).unfocus();
    AuthScope.read(context).clearError();
    setState(() => _method = method);
  }

  Future<void> _submitPhone(AuthController auth) async {
    if (!(_phoneKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await auth.requestOtp(_phoneController.text, _country);
  }

  Future<void> _submitEmail(AuthController auth) async {
    if (!(_emailKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await auth.signInWithEmail(_emailController.text, _passwordController.text);
  }

  void _openSignup(AuthController auth) {
    auth.clearError();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final onCodeStep = auth.phoneStep == PhoneStep.code;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              children: [
                const FadeInUp(child: _Branding()),
                const SizedBox(height: 28),
                FadeInUp(
                  delay: const Duration(milliseconds: 90),
                  child: AnimatedSize(
                    duration: AppMotion.medium,
                    curve: AppMotion.emphasized,
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.card,
                      ),
                      child: onCodeStep
                          ? _OtpStep(auth: auth)
                          : _buildCredentialsStep(auth),
                    ),
                  ),
                ),
                if (!onCodeStep) ...[
                  const SizedBox(height: 18),
                  FadeInUp(
                    delay: const Duration(milliseconds: 180),
                    child: _SignupCallout(onTap: () => _openSignup(auth)),
                  ),
                ],
                const SizedBox(height: 20),
                const FadeInUp(
                  delay: Duration(milliseconds: 240),
                  child: Text(
                    'En continuant, vous acceptez les conditions d\'utilisation '
                    'et la politique de confidentialité de JaBa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsStep(AuthController auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MethodSwitch(method: _method, onChanged: _switchMethod),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: AppMotion.medium,
          switchInCurve: AppMotion.emphasized,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topLeft,
              child: child,
            ),
          ),
          child: _method == _Method.phone
              ? _buildPhoneForm(auth)
              : _buildEmailForm(auth),
        ),
        if (auth.error != null) ...[
          const SizedBox(height: 12),
          ErrorBanner(message: auth.error!),
        ],
      ],
    );
  }

  Widget _buildPhoneForm(AuthController auth) {
    return Form(
      key: _phoneKey,
      child: Column(
        key: const ValueKey('phone'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connectez-vous avec votre numéro',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Vous recevrez un code de vérification par SMS.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
              LengthLimitingTextInputFormatter(_country.maxLength + 5),
            ],
            validator: (value) => AuthController.validatePhone(value, _country),
            onFieldSubmitted: (_) => _submitPhone(auth),
            decoration: InputDecoration(
              // Sélecteur d'indicatif intégré au champ.
              prefixIcon: CountryCodeField(
                country: _country,
                enabled: !auth.busy,
                onChanged: (country) {
                  // Le format attendu change : on repart d'un champ propre.
                  setState(() {
                    _country = country;
                    _phoneController.clear();
                  });
                  auth.clearError();
                },
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: _country.exampleNumber,
            ),
          ),
          const SizedBox(height: 18),
          _SubmitButton(
            label: 'Recevoir le code',
            icon: Icons.sms_outlined,
            busy: auth.busy,
            onPressed: () => _submitPhone(auth),
          ),
          const SizedBox(height: 14),
          const _DividerWithLabel(label: 'ou'),
          const SizedBox(height: 14),
          _SecondaryButton(
            icon: Icons.mail_outline,
            label: 'Continuer avec un e-mail',
            onPressed: auth.busy ? null : () => _switchMethod(_Method.email),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm(AuthController auth) {
    return Form(
      key: _emailKey,
      child: Column(
        key: const ValueKey('email'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connectez-vous avec votre e-mail',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: AuthController.validateEmail,
            decoration: const InputDecoration(
              labelText: 'Adresse e-mail',
              hintText: 'prenom@exemple.sn',
              prefixIcon: Icon(Icons.alternate_email, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: AuthController.validatePassword,
            onFieldSubmitted: (_) => _submitEmail(auth),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                tooltip: _obscurePassword
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPassword(context),
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          const SizedBox(height: 4),
          _SubmitButton(
            label: 'Se connecter',
            icon: Icons.login,
            busy: auth.busy,
            onPressed: () => _submitEmail(auth),
          ),
          const SizedBox(height: 14),
          const _DividerWithLabel(label: 'ou'),
          const SizedBox(height: 14),
          _SecondaryButton(
            icon: Icons.smartphone_outlined,
            label: 'Continuer avec mon numéro',
            onPressed: auth.busy ? null : () => _switchMethod(_Method.phone),
          ),
        ],
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: const Text(
          'Un lien de réinitialisation sera envoyé à votre adresse e-mail. '
          'Cette fonctionnalité sera activée avec le branchement de Firebase Auth.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

/// Invitation à créer un compte, visible quel que soit l'onglet choisi.
class _SignupCallout extends StatelessWidget {
  const _SignupCallout({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          const Text(
            'Vous n\'avez pas encore de compte ?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Créez le vôtre en une minute pour acheter, vendre et discuter.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Créer un compte'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fond décoratif : deux halos colorés qui donnent de la profondeur à l'écran
/// sans recourir à une image de fond.
class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _Halo(size: 300, color: AppColors.primary.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _Halo(size: 260, color: AppColors.accent.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const JaBaMark(size: 46),
            const SizedBox(width: 12),
            // Sur les écrans étroits, le wordmark se réduit au lieu de déborder.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5),
                    children: [
                      TextSpan(
                          text: 'Ja',
                          style: TextStyle(color: AppColors.primary)),
                      TextSpan(
                          text: 'BA', style: TextStyle(color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'La seconde main, en confiance, entre Sénégalais',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Sélecteur de méthode animé : l'indicateur glisse d'un onglet à l'autre.
class _MethodSwitch extends StatelessWidget {
  const _MethodSwitch({required this.method, required this.onChanged});

  final _Method method;
  final ValueChanged<_Method> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 8) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: AppMotion.medium,
                curve: AppMotion.emphasized,
                alignment: method == _Method.phone
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: tabWidth,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  _tab(_Method.phone, Icons.smartphone_outlined, 'Téléphone', tabWidth),
                  _tab(_Method.email, Icons.alternate_email, 'E-mail', tabWidth),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tab(_Method value, IconData icon, String label, double width) {
    final active = method == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 34,
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.medium,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.background : AppColors.textSecondary,
          ),
          // Les libellés (« Téléphone ») se réduisent plutôt que de déborder
          // sur les petits écrans.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 15,
                    color: active ? AppColors.background : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Étape de saisie du code : six cases, avance automatique, compte à rebours
/// de validité et renvoi du code.
class _OtpStep extends StatefulWidget {
  const _OtpStep({required this.auth});

  final AuthController auth;

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _fill(String code) {
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = i < code.length ? code[i] : '';
    }
    setState(() {});
  }

  void _onDigitChanged(int index, String value) {
    widget.auth.clearError();

    // Collage du code complet dans la première case.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      _fill(digits);
      _focusNodes[(digits.length - 1).clamp(0, 5)].requestFocus();
      if (digits.length >= 6) _submit();
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
    if (_code.length == 6) _submit();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final success = await widget.auth.verifyOtp(_code);
    if (!success && mounted) {
      _fill('');
      if (widget.auth.phoneStep == PhoneStep.code) {
        _focusNodes.first.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: auth.busy ? null : auth.backToPhoneNumber,
              tooltip: 'Changer de numéro',
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Entrez le code reçu',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Code à 6 chiffres envoyé au ${auth.pendingPhoneLabel}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        // Faute de passerelle SMS, le message est simulé — mais présenté
        // comme la notification qu'on recevrait réellement.
        if (auth.sentCode != null)
          _SimulatedSms(
            code: auth.sentCode!,
            onUse: () {
              _fill(auth.sentCode!);
              _submit();
            },
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _buildDigitField(i)),
        ),
        const SizedBox(height: 12),
        CountdownText(
          secondsLeft: () => auth.otpSecondsLeft,
          builder: (context, seconds) {
            if (seconds <= 0) {
              return const Text(
                'Code expiré — demandez-en un nouveau',
                style: TextStyle(fontSize: 11.5, color: AppColors.danger),
              );
            }
            final m = (seconds ~/ 60).toString();
            final s = (seconds % 60).toString().padLeft(2, '0');
            return Row(
              children: [
                const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  'Code valable encore $m:$s',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            );
          },
        ),
        if (auth.error != null) ...[
          const SizedBox(height: 12),
          ErrorBanner(message: auth.error!),
        ],
        const SizedBox(height: 18),
        _SubmitButton(
          label: 'Valider le code',
          icon: Icons.check_circle_outline,
          busy: auth.busy,
          onPressed: _code.length == 6 ? _submit : null,
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton.icon(
            onPressed: auth.busy
                ? null
                : () async {
                    _fill('');
                    await auth.resendOtp();
                    if (mounted) _focusNodes.first.requestFocus();
                  },
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('Renvoyer le code'),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitField(int index) {
    final filled = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 44,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          // Retour arrière sur une case vide : on remonte à la précédente.
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _controllers[index - 1].clear();
            _focusNodes[index - 1].requestFocus();
            setState(() {});
          }
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled ? AppColors.primary : AppColors.border,
              width: filled ? 1.5 : 1,
            ),
            color: AppColors.surface,
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: index == 0 ? 6 : 1,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) => _onDigitChanged(index, value),
          ),
        ),
      ),
    );
  }
}

/// Notification imitant le SMS de vérification, avec le code réellement
/// généré pour cette session.
class _SimulatedSms extends StatelessWidget {
  const _SimulatedSms({required this.code, required this.onUse});

  final String code;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(code),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, -12 * (1 - value)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sms, size: 16, color: AppColors.success),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SMS · JaBa',
                    style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Votre code de vérification est $code',
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onUse,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Utiliser'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'erreur qui apparaît en glissant, plutôt qu'un texte rouge figé.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(message),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 8 * (1 - value)), child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton principal qui bascule en indicateur de chargement pendant l'appel.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: busy
              ? const SizedBox(
                  key: ValueKey('busy'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.background,
                  ),
                )
              : Row(
                  key: const ValueKey('idle'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 17),
                      const SizedBox(width: 8),
                    ],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _DividerWithLabel extends StatelessWidget {
  const _DividerWithLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
