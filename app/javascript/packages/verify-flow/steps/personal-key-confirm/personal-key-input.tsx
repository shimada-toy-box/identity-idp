import { forwardRef, useCallback } from 'react';
import type { ForwardedRef } from 'react';
import Cleave from 'cleave.js/react';
import { t } from '@18f/identity-i18n';
import { ValidatedField } from '@18f/identity-validated-field';
import type { ValidatedFieldValidator } from '@18f/identity-validated-field';

interface PersonalKeyInputProps {
  /**
   * The correct personal key to validate against.
   */
  expectedValue?: string;

  /**
   * Callback invoked when the value of the input has changed.
   */
  onChange?: (nextValue: string) => void;
}

function PersonalKeyInput(
  { expectedValue, onChange = () => {} }: PersonalKeyInputProps,
  ref: ForwardedRef<HTMLElement>,
) {
  const validate = useCallback<ValidatedFieldValidator>(
    (value) => {
      if (expectedValue && value !== expectedValue) {
        throw new Error(t('users.personal_key.confirmation_error'));
      }
    },
    [expectedValue],
  );

  return (
    <ValidatedField validate={validate}>
      <Cleave
        options={{
          blocks: [4, 4, 4, 4],
          delimiter: '-',
        }}
        htmlRef={(cleaveRef) => typeof ref === 'function' && ref(cleaveRef)}
        aria-label={t('forms.personal_key.confirmation_label')}
        autoComplete="off"
        className="width-full field font-family-mono text-uppercase"
        pattern="[a-zA-Z0-9-]+"
        spellCheck={false}
        type="text"
        onInput={(event) => onChange((event.target as HTMLInputElement).value)}
      />
    </ValidatedField>
  );
}

export default forwardRef(PersonalKeyInput);