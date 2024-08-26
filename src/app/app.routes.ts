import { Routes } from '@angular/router';
import { SignInComponent } from './modules/auth/sign-in/sign-in.component';

export const routes: Routes = [
    { path: '**', component: SignInComponent },
    { path: 'sign-in', component: SignInComponent },
    { path: '', redirectTo: 'sign-in', pathMatch: 'full' },
];