import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/auth_controller.dart';
import '../../data/countries.dart';
import '../../data/demo_catalog.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/country_picker.dart';
import 'login_screen.dart' show ErrorBanner;

/// Création de compte : le profil créé ici est réellement enregistré en
/// mémoire et permet de se reconnecter ensuite avec les mêmes identifiants.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  Country _country = Countries.senegal;
  String _zone = DemoData.zones.first;
  bool _obscure = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    // Le témoin de robustesse suit la frappe.
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation'),
          backgroundColor: AppColors.danger,
        ));
      return;
    }
    FocusScope.of(context).unfocus();

    final created = await auth.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      zone: _zone,
      phone: _phoneController.text,
      country: _country,
    );
    // Succès : l'AuthGate bascule seul sur l'application, il suffit de
    // refermer cet écran pour ne pas le laisser dans la pile.
    if (created && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            auth.clearError();
            Navigator.pop(context);
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            const FadeInUp(
              child: Text(
                'Rejoignez la communauté',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            const FadeInUp(
              delay: Duration(milliseconds: 60),
              child: Text(
                'Vendez ce que vous ne portez plus, trouvez la bonne affaire '
                'près de chez vous.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 26),
            FadeInUp(
              delay: const Duration(milliseconds: 120),
              child: TextFormField(
                key: const Key('signup-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: AuthController.validateName,
                decoration: const InputDecoration(
                  labelText: 'Nom et prénom',
                  hintText: 'Aïda Diallo',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeInUp(
              delay: const Duration(milliseconds: 160),
              child: TextFormField(
                key: const Key('signup-email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: AuthController.validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Adresse e-mail',
                  hintText: 'prenom@exemple.sn',
                  prefixIcon: Icon(Icons.alternate_email, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeInUp(
              delay: const Duration(milliseconds: 180),
              child: TextFormField(
                key: const Key('signup-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
                  LengthLimitingTextInputFormatter(_country.maxLength + 5),
                ],
                validator: (value) =>
                    AuthController.validatePhone(value, _country),
                decoration: InputDecoration(
                  // Indicatif sélectionnable : le compte peut être créé avec
                  // un numéro étranger.
                  prefixIcon: CountryCodeField(
                    country: _country,
                    onChanged: (country) => setState(() {
                      _country = country;
                      _phoneController.clear();
                    }),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: _country.exampleNumber,
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: TextFormField(
                key: const Key('signup-password'),
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                validator: AuthController.validatePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  helperText: '8 caractères minimum',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ),
            // Toujours présent dans l'arbre (il se contente d'être vide quand
            // le mot de passe l'est) : l'insérer/retirer décalerait les
            // enfants suivants de la ListView, qui perdraient alors leur état
            // — le champ de confirmation se vidait tout seul à la frappe.
            _PasswordStrengthBar(value: _passwordController.text),
            const SizedBox(height: 14),
            FadeInUp(
              delay: const Duration(milliseconds: 240),
              child: TextFormField(
                key: const Key('signup-confirm'),
                controller: _confirmController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirmez votre mot de passe';
                  }
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock_reset_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeInUp(
              delay: const Duration(milliseconds: 280),
              child: DropdownButtonFormField<String>(
                initialValue: _zone,
                decoration: const InputDecoration(
                  labelText: 'Zone habituelle de remise',
                  prefixIcon: Icon(Icons.place_outlined, size: 18),
                ),
                items: DemoData.zones
                    .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                    .toList(),
                onChanged: (value) => setState(() => _zone = value ?? _zone),
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              key: const Key('signup-terms'),
              value: _acceptTerms,
              onChanged: (v) => setState(() => _acceptTerms = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              title: const Text(
                'J\'accepte les conditions d\'utilisation et la politique '
                'de confidentialité',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 6),
              ErrorBanner(message: auth.error!),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('signup-submit'),
                onPressed: auth.busy ? null : () => _submit(auth),
                child: auth.busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.background),
                      )
                    : const Text('Créer mon compte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Jauge de robustesse du mot de passe, qui se remplit et change de couleur
/// au fil de la frappe.
class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox(width: double.infinity);

    final strength = AuthController.passwordStrength(value);
    final label = AuthController.passwordStrengthLabel(value);
    final color = strength < 0.4
        ? AppColors.danger
        : (strength < 0.7 ? AppColors.warning : AppColors.success);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: strength),
                duration: AppMotion.medium,
                curve: AppMotion.emphasized,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
