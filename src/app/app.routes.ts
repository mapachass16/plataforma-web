import { Routes } from '@angular/router';
import { SignInComponent } from './modules/auth/sign-in/sign-in.component';
import { SignUpComponent } from './modules/auth/sign-up/sign-up.component';

export const routes: Routes = [
    { path: 'sign-in', component: SignInComponent },
    { path: 'sign-up', component: SignUpComponent },
    { path: '', redirectTo: 'sign-in', pathMatch: 'full' },
    { path: '**', component: SignInComponent },
];