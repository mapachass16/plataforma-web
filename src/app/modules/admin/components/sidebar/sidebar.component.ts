import { Component } from '@angular/core';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatListModule } from '@angular/material/list';
import { RouterModule } from '@angular/router';
import { Router } from '@angular/router';
import { SupabaseService } from '../../../../services/supabase.service';


@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [
    MatSidenavModule,
    MatToolbarModule,
    MatIconModule,
    MatButtonModule,
    MatListModule,
    RouterModule],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.scss'
})
export class SidebarComponent {
  email: any;

  constructor(
    private _router: Router,
    private _supabaseService: SupabaseService
  ) { }

  /**
   * Function that brings the information of the logged in user
   */
  async ngOnInit() {
    const user = await this._supabaseService.getUserSession();
    this.email = user?.data?.user?.email;
  }

  /**
   * Function that logs out and redirects to login
   */
  public logout() {
    this._router.navigate(['/auth/sign-in']);
  }
}
