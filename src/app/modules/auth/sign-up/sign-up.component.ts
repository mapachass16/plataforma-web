import { Component, ChangeDetectionStrategy } from '@angular/core';
import { MatCardModule } from '@angular/material/card';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { ReactiveFormsModule } from '@angular/forms';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-sign-up',
  standalone: true,
  imports: [MatCardModule, MatInputModule, MatFormFieldModule, MatIconModule, MatButtonModule, ReactiveFormsModule, MatCheckboxModule, CommonModule],
  templateUrl: './sign-up.component.html',
  styleUrl: './sign-up.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SignUpComponent {
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

  onSubmit() {
    if (this.signUpForm.valid) {
      console.log(this.signUpForm.value); // Aquí obtienes los valores del formulario
    }
  }

  public signIn() {
    this._router.navigate(['/sign-in']);
  }

  public checkPassword() {
    const password = this.signUpForm.get('password')?.value;
    const password2 = this.signUpForm.get('password2')?.value;

    if (password && password2 && password !== password2) {
      this.signUpForm.get('password2')?.setErrors({ matchWith: true });
    } else {
      this.signUpForm.get('password2')?.setErrors(null);
    }
  }

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

