import { useCallback, useLayoutEffect, useMemo, useState } from 'react';

interface UseUncontrolledStateOptions<T> {
  defaultValue: T;
}

// Enables updates to default value when using uncontrolled inputs
const useUncontrolledState = <T>(options: UseUncontrolledStateOptions<T>) => {
  const [state, setState] = useState({
    defaultValue: options.defaultValue,
    value: options.defaultValue,
    key: 0,
  });

  const setValue = useCallback(
    (val: T) =>
      setState((prev) => ({
        ...prev,
        value: val,
      })),
    []
  );

  const setDefaultValue = useCallback(
    (defaultVal: T) =>
      setState((prev) => ({
        key: prev.key + 1,
        value: defaultVal,
        defaultValue: defaultVal,
      })),
    []
  );

  const resetValue = useCallback(
    () =>
      setState((prev) => ({
        ...prev,
        value: prev.defaultValue,
        key: prev.key + 1,
      })),
    []
  );

  useLayoutEffect(() => {
    setDefaultValue(options.defaultValue);
  }, [options.defaultValue]);

  return useMemo(
    () => ({
      ...state,
      setValue,
      setDefaultValue,
      resetValue,
    }),
    [state]
  );
};

export default useUncontrolledState;
