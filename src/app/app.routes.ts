import { Routes } from '@angular/router';
import { SignInComponent } from './modules/auth/pages/sign-in/sign-in.component';
import { SignUpComponent } from './modules/auth/pages/sign-up/sign-up.component';
import { DashboardComponent } from './modules/admin/pages/dashboard/dashboard.component';

export const routes: Routes = [
    {
        path: 'auth', children: [
            { path: 'sign-in', component: SignInComponent },
            { path: 'sign-up', component: SignUpComponent, },
        ]
    },
    {
        path: 'admin', children: [
            { path: 'dashboard', component: DashboardComponent },
        ]
    },
    { path: '', redirectTo: 'auth/sign-in', pathMatch: 'full' },
    //{ path: '**', component: SignInComponent },
];