angular.module 'ahaLuminateControllers'
  .controller 'CompanyListPageCtrl', [
    '$scope'
    '$filter'
    'TeamraiserCompanyService'
    ($scope, $filter, TeamraiserCompanyService) ->
      $scope.topCompanies = 
        'ng_sort_column': null
        'ng_sort_reverse': null
      
      $scope.sortCompanyList = (column) ->
        if $scope.topCompanies.ng_sort_column is column and $scope.topCompanies.ng_sort_reverse is false
          $scope.topCompanies.ng_sort_reverse = true
        else
          $scope.topCompanies.ng_sort_reverse = false
        $scope.topCompanies.companies = $filter('orderBy') $scope.topCompanies.companies, column, $scope.topCompanies.ng_sort_reverse
        $scope.topCompanies.ng_sort_column = column
        if not $scope.$$phase
          $scope.$apply()
      
      setTopCompanies = (companies) ->
        $scope.topCompanies.companies = companies
        if not $scope.$$phase
          $scope.$apply()
          
      TeamraiserCompanyService.getCompanyList 'include_all_companies=true', 
        error: ->
          setTopCompanies []
        success: (response) ->
          companyItems = response.getCompanyListResponse?.companyItem or []
          companyItems = [companyItems] if not angular.isArray companyItems
          rootAncestorCompanies = []
          childCompanyIdMap = {}
          angular.forEach companyItems, (companyItem) ->
            if companyItem.parentOrgEventId is '0'
              rootAncestorCompany =
                eventId: $scope.frId
                companyId: companyItem.companyId
                companyName: companyItem.companyName
                amountRaised: if companyItem.amountRaised then Number(companyItem.amountRaised) else 0
              rootAncestorCompanies.push rootAncestorCompany
          angular.forEach companyItems, (companyItem) ->
            parentOrgEventId = companyItem.parentOrgEventId
            if parentOrgEventId isnt '0'
              childCompanyIdMap['company-' + companyItem.companyId] = parentOrgEventId
          angular.forEach childCompanyIdMap, (value, key) ->
            if childCompanyIdMap['company-' + value]
              childCompanyIdMap[key] = childCompanyIdMap['company-' + value]
          angular.forEach childCompanyIdMap, (value, key) ->
            if childCompanyIdMap['company-' + value]
              childCompanyIdMap[key] = childCompanyIdMap['company-' + value]
          angular.forEach companyItems, (companyItem) ->
            if companyItem.parentOrgEventId isnt '0'
              rootParentCompanyId = childCompanyIdMap['company-' + companyItem.companyId]
              childCompanyAmountRaised = if companyItem.amountRaised then Number(companyItem.amountRaised) else 0
              angular.forEach rootAncestorCompanies, (rootAncestorCompany, rootAncestorCompanyIndex) ->
                if rootAncestorCompany.companyId is rootParentCompanyId
                  rootAncestorCompanies[rootAncestorCompanyIndex].amountRaised = rootAncestorCompanies[rootAncestorCompanyIndex].amountRaised + childCompanyAmountRaised
          angular.forEach rootAncestorCompanies, (rootAncestorCompany, rootAncestorCompanyIndex) ->
            rootAncestorCompanies[rootAncestorCompanyIndex].amountRaisedFormatted = $filter('currency') rootAncestorCompany.amountRaised / 100, '$', 0
          TeamraiserCompanyService.getCompanies 'list_sort_column=total&list_ascending=false&list_page_size=500', 
            error: ->
              setTopCompanies []
            success: (response) ->
              companies = response.getCompaniesResponse?.company or []
              companies = [companies] if not angular.isArray companies
              angular.forEach companies, (company) ->
                companyId = company.companyId
                participantCount = if company.participantCount then Number(company.participantCount) else 0
                teamCount = if company.teamCount then Number(company.teamCount) else 0
                angular.forEach rootAncestorCompanies, (rootAncestorCompany, rootAncestorCompanyIndex) ->
                  if rootAncestorCompany.companyId is companyId
                    rootAncestorCompanies[rootAncestorCompanyIndex].participantCount = participantCount
                    rootAncestorCompanies[rootAncestorCompanyIndex].teamCount = teamCount
              angular.forEach companies, (company) ->
                companyId = company.companyId
                rootParentCompanyId = childCompanyIdMap['company-' + companyId]
                if rootParentCompanyId
                  participantCount = if company.participantCount then Number(company.participantCount) else 0
                  teamCount = if company.teamCount then Number(company.teamCount) else 0
                  angular.forEach rootAncestorCompanies, (rootAncestorCompany, rootAncestorCompanyIndex) ->
                    if rootAncestorCompany.companyId is rootParentCompanyId
                      rootAncestorCompanies[rootAncestorCompanyIndex].participantCount = rootAncestorCompanies[rootAncestorCompanyIndex].participantCount + participantCount
                      rootAncestorCompanies[rootAncestorCompanyIndex].teamCount = rootAncestorCompanies[rootAncestorCompanyIndex].teamCount + teamCount
              setTopCompanies rootAncestorCompanies
              $scope.sortCompanyList 'companyName'
  ]