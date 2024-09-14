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
import { HeroService } from '../../../../services/hero.service';
import { Subscription } from 'rxjs';

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
export class SignInComponent implements OnInit {
  hide = true;
  loginForm: FormGroup;
  deviceUsers: any;
  heroes: any;
  isLoading: boolean = true;


  constructor(
    private _router: Router,
    private _supabaseService: SupabaseService,
    private _heroService: HeroService,
  ) {
    this.loginForm = new FormGroup({
      email: new FormControl('', [Validators.required, Validators.email]),
      password: new FormControl('', [Validators.required]),
    });
  }

  async ngOnInit() {
    this.heroes = this._heroService.getHeroes()
    console.log(this.heroes)
    await this.fetchDeviceUsers();
  }

  async fetchDeviceUsers() {
    try {
      const response = await this._supabaseService.getDeviceUsers();
      if (response.data) {
        this.deviceUsers = response.data;  // Asegúrate de que no haya cambios continuos
      }
      console.log('Device users:', this.deviceUsers);
    } catch (error) {
      console.error('Error fetching device users:', error);
    }
  }

  onSubmit() {
    if (this.loginForm.valid) {
      console.log(this.loginForm.value);
      //this.fetchDeviceUsers()
      this._router.navigate(['/admin/dashboard']);
    }
  }

  public createAccount() {
    this._router.navigate(['/auth/sign-up']);
  }
}
