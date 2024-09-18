import { Component, ChangeDetectionStrategy, inject } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import {
  MatDialog,
  MatDialogActions,
  MatDialogClose,
  MatDialogContent,
  MatDialogTitle,
} from '@angular/material/dialog';
import { MatCardModule } from '@angular/material/card';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { ReactiveFormsModule } from '@angular/forms';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-dialog-create-tenant',
  standalone: true,
  imports: [MatDialogTitle, MatDialogContent, MatDialogActions, MatDialogClose, MatButtonModule, MatCardModule, MatInputModule, MatFormFieldModule, MatIconModule, MatButtonModule, ReactiveFormsModule, MatCheckboxModule, CommonModule],
  templateUrl: './dialog-create-tenant.component.html',
  styleUrl: './dialog-create-tenant.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DialogCreateTenantComponent {
  hide = true;
  hide2 = true;
  signUpForm: FormGroup;
  family = false;
  company = false;

  constructor(
    private _router: Router
  ) {
    this.signUpForm = new FormGroup({
      name: new FormControl('', [Validators.required]),
      companyName: new FormControl(''),
      email: new FormControl('', [Validators.required, Validators.email]),
      password: new FormControl('', [Validators.required]),
      password2: new FormControl('', [Validators.required]),

    });

    this.signUpForm.valueChanges.subscribe(() => {
      this.checkPassword();
    });
  }

  /**
   * Function that would create the new account
   */
  public onSubmit() {
    if (this.signUpForm.valid) {
      console.log("crear cuenta")
    }
  }

  /**
   * Function that checks that the two passwords are the same
   */
  public checkPassword() {
    const password = this.signUpForm.get('password')?.value;
    const password2 = this.signUpForm.get('password2')?.value;

    if (password && password2 && password !== password2) {
      this.signUpForm.get('password2')?.setErrors({ matchWith: true });
    } else {
      if (this.signUpForm.get('password2')?.hasError('required')) {
        return;
      }
      this.signUpForm.get('password2')?.setErrors(null);
    }
  }

  /**
   * Function that changes the account type when the person click on the other account type
   */
  public changeTypeAccount(type: string) {
    if (type === "family") {
      this.family = true;
      this.company = false;
    } else {
      this.company = true;
      this.family = false
    }

  }
}
