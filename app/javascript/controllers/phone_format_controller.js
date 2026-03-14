import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  format(event) {
    const input = event.target
    const digits = input.value.replace(/\D/g, "").slice(0, 11)
    let formatted = digits

    if (digits.length > 7) {
      formatted = `${digits.slice(0, 3)}-${digits.slice(3, 7)}-${digits.slice(7)}`
    } else if (digits.length > 3) {
      formatted = `${digits.slice(0, 3)}-${digits.slice(3)}`
    }

    input.value = formatted
  }
}
