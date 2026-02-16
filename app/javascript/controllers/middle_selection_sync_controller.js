import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { selectedItemId: Number }

  connect() {
    const rows = document.querySelectorAll(".items-table tbody tr")
    rows.forEach((row) => row.classList.remove("is-selected"))

    if (!this.hasSelectedItemIdValue) return

    const selectedRow = document.querySelector(
      `.items-table tbody tr[data-item-id="${this.selectedItemIdValue}"]`
    )
    if (selectedRow) selectedRow.classList.add("is-selected")
  }
}
