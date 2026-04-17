import { reactive, type Ref } from 'vue'

type Rule = (value: unknown) => string | true
type Rules<T> = Partial<Record<keyof T, Rule[]>>
type Errors<T> = Record<keyof T, string>

export function useFormValidation<T extends Record<string, unknown>>(
  form: Ref<T>,
  rules: Rules<T>,
) {
  const errors = reactive<Record<string, string>>({}) as Errors<T>

  function validateField(field: keyof T): boolean {
    const fieldRules = rules[field]
    if (!fieldRules) {
      errors[field] = '' as Errors<T>[keyof T]
      return true
    }
    for (const rule of fieldRules) {
      const result = rule(form.value[field])
      if (result !== true) {
        errors[field] = result as Errors<T>[keyof T]
        return false
      }
    }
    errors[field] = '' as Errors<T>[keyof T]
    return true
  }

  function validate(): boolean {
    let valid = true
    for (const field of Object.keys(rules) as (keyof T)[]) {
      if (!validateField(field)) {
        valid = false
      }
    }
    return valid
  }

  function clearErrors() {
    for (const key of Object.keys(errors)) {
      (errors as Record<string, string>)[key] = ''
    }
  }

  return { errors, validate, validateField, clearErrors }
}

// 常用校验规则工厂
export const required = (label: string): Rule => (v) =>
  v !== null && v !== undefined && String(v).trim() !== '' ? true : `${label}不能为空`

export const minLength = (label: string, min: number): Rule => (v) =>
  String(v).length >= min ? true : `${label}至少 ${min} 个字符`

export const maxLength = (label: string, max: number): Rule => (v) =>
  String(v).length <= max ? true : `${label}最多 ${max} 个字符`

export const positiveNumber = (label: string): Rule => (v) => {
  const n = Number(v)
  return !isNaN(n) && n > 0 ? true : `${label}必须为正数`
}
