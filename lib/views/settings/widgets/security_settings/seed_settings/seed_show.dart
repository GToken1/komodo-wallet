import 'package:app_theme/app_theme.dart';
import 'package:bip39/bip39.dart' show validateMnemonic;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_bloc.dart';
import 'package:web_dex/bloc/security_settings/security_settings_event.dart';
import 'package:web_dex/bloc/security_settings/security_settings_state.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/shared/utils/utils.dart';
import 'package:web_dex/shared/widgets/dry_intrinsic.dart';
import 'package:web_dex/views/settings/widgets/security_settings/seed_settings/seed_back_button.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';

class SeedShow extends StatelessWidget {
  const SeedShow({required this.seedPhrase});
  final String seedPhrase;

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return DexScrollbar(
      scrollController: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!isMobile)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SeedBackButton(() => context
                    .read<SecuritySettingsBloc>()
                    .add(const ResetEvent())),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TitleRow(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ShowingSwitcher(),
                      _CopySeedButton(seed: seedPhrase),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(child: _SeedPlace(seedPhrase: seedPhrase)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SeedPhraseConfirmButton(seedPhrase: seedPhrase)
          ],
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.seedPhraseShowingTitle.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(LocaleKeys.seedPhraseMakeSureBody.tr(),
            style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _CopySeedButton extends StatelessWidget {
  const _CopySeedButton({required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          copyToClipBoard(context, seed);
          context.read<SecuritySettingsBloc>().add(const ShowSeedCopiedEvent());
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: Row(
            children: [
              Icon(
                Icons.copy,
                size: 16,
                color: theme.currentGlobal.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 10),
              Text(
                LocaleKeys.seedPhraseShowingCopySeed.tr(),
                style: theme.currentGlobal.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowingSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SecuritySettingsBloc>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiSwitcher(
          value: bloc.state.showSeedWords,
          onChanged: (isChecked) => bloc.add(ShowSeedWordsEvent(isChecked)),
          width: 38,
          height: 21,
        ),
        const SizedBox(width: 6),
        SelectableText(
          LocaleKeys.seedPhraseShowingShowPhrase.tr(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}

class _SeedPlace extends StatelessWidget {
  const _SeedPlace({required this.seedPhrase});
  final String seedPhrase;

  @override
  Widget build(BuildContext context) {
    final isCustom = !validateMnemonic(seedPhrase);
    if (isCustom) return _SeedField(seedPhrase: seedPhrase);
    return _WordsList(seedPhrase: seedPhrase);
  }
}

class _SeedField extends StatelessWidget {
  const _SeedField({required this.seedPhrase});
  final String seedPhrase;

  @override
  Widget build(BuildContext context) {
    final width = screenWidth - 80.0;

    return BlocSelector<SecuritySettingsBloc, SecuritySettingsState, bool>(
      selector: (state) => state.showSeedWords,
      builder: (context, showSeedWords) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? width : 380),
          child: TextField(
            controller: TextEditingController()
              ..text = showSeedWords ? seedPhrase : _obscured(seedPhrase),
            maxLines: 12,
            minLines: 5,
            readOnly: true,
          ),
        );
      },
    );
  }

  String _obscured(String source, {String obscuringCharacter = '•'}) {
    if (source.isEmpty) return '';
    if (obscuringCharacter.length > 1) {
      obscuringCharacter = obscuringCharacter.substring(0, 1);
    } else if (obscuringCharacter.isEmpty) {
      obscuringCharacter = '•';
    }
    final length = source.length;
    String result = '';
    for (int i = 0; i < length; i++) {
      result += source.codeUnitAt(i) == 32 ? ' ' : obscuringCharacter;
    }
    return result;
  }
}

class _WordsList extends StatelessWidget {
  const _WordsList({required this.seedPhrase});
  final String seedPhrase;

  @override
  Widget build(BuildContext context) {
    final double runSpacing = isMobile ? 15 : 20;

    final bloc = context.read<SecuritySettingsBloc>();
    final showSeedWords = bloc.state.showSeedWords;

    final seedList = seedPhrase.split(' ');

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        runSpacing: runSpacing,
        alignment: WrapAlignment.spaceBetween,
        children: seedList
            .asMap()
            .map<int, Widget>(
                (index, w) => _buildSeedWord(index, w, showSeedWords))
            .values
            .toList(),
      ),
    );
  }

  MapEntry<int, Widget> _buildSeedWord(int i, String word, bool showSeedWords) {
    return MapEntry(
      i,
      _SelectableSeedWord(
        initialValue: word,
        isSeedShown: showSeedWords,
        index: i,
      ),
    );
  }
}

class _SelectableSeedWord extends StatelessWidget {
  const _SelectableSeedWord({
    Key? key,
    required this.isSeedShown,
    required this.initialValue,
    required this.index,
  }) : super(key: key);

  final bool isSeedShown;
  final String initialValue;
  final int index;

  @override
  Widget build(BuildContext context) {
    final numStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
    );
    final TextEditingController seedWordController = TextEditingController()
      ..text = isSeedShown ? initialValue : '••••••';

    return Focus(
      descendantsAreFocusable: true,
      skipTraversal: true,
      onFocusChange: (value) {
        if (value) {
          seedWordController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: seedWordController.value.text.length,
          );
        }
      },
      child: FractionallySizedBox(
        widthFactor: isMobile ? 0.5 : 0.25,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 21,
              child: Text(
                '${index + 1}.',
                style: numStyle,
              ),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 31),
                child: DryIntrinsicWidth(
                  child: UiTextFormField(
                    obscureText: !isSeedShown,
                    readOnly: true,
                    controller: seedWordController,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class _SeedPhraseConfirmButton extends StatelessWidget {
  const _SeedPhraseConfirmButton({required this.seedPhrase});
  final String seedPhrase;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SecuritySettingsBloc>();
    final isCustom = !validateMnemonic(seedPhrase);
    if (isCustom) return const SizedBox.shrink();

    onPressed() => bloc.add(const SeedConfirmEvent());
    final text = LocaleKeys.seedPhraseShowingSavedPhraseButton.tr();

    final contentWidth = screenWidth - 80;
    final width = isMobile ? contentWidth : 207.0;
    final height = isMobile ? 52.0 : 40.0;

    return BlocSelector<SecuritySettingsBloc, SecuritySettingsState, bool>(
      selector: (state) => state.isSeedSaved,
      builder: (context, isSaved) {
        return UiPrimaryButton(
          width: width,
          height: height,
          text: text,
          onPressed: isSaved ? onPressed : null,
        );
      },
    );
  }
}
