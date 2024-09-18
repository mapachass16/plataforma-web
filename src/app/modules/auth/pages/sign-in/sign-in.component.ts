import { Component, ChangeDetectionStrategy, OnInit, ChangeDetectorRef } from '@angular/core';
import { Router } from '@angular/router';
import { FormControl, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { SupabaseService } from '../../../../services/supabase.service';
import { MatCardModule } from '@angular/material/card';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-sign-in',
  standalone: true,
  imports: [
    MatCardModule, MatInputModule, MatFormFieldModule,
    MatIconModule, MatButtonModule, ReactiveFormsModule, MatCheckboxModule, CommonModule
  ],
  templateUrl: './sign-in.component.html',
  styleUrls: ['./sign-in.component.scss'],
  changeDetection: ChangeDetectionStrategy.Default
})
export class SignInComponent {
  hide = true;
  loginForm: FormGroup;
  deviceUsers: any;
  heroes: any;
  isLoading: boolean = true;


  constructor(
    private _router: Router,
    private _supabaseService: SupabaseService,
  ) {
    this.loginForm = new FormGroup({
      email: new FormControl('', [Validators.required, Validators.email]),
      password: new FormControl('', [Validators.required]),
    });
  }

  /**
   * Function with which the user's credentials are validated
   */
  public async onSubmit() {
    if (this.loginForm.valid) {
      try {
        const { user, error } = await this._supabaseService.signIn(this.loginForm.value.email, this.loginForm.value.password);
        if (error) {
          window.alert("Credenciales incorrectas");
        } else {
          this._router.navigate(['/admin/dashboard']);
        }
      } catch (e) {
        window.alert("Ocurrió un error inesperado. Inténtalo de nuevo más tarde.");
      }
    }
  }

  /**
   * Function that redirects to the screen to create an account
   */
  public createAccount() {
    this._router.navigate(['/auth/sign-up']);
  }
}
